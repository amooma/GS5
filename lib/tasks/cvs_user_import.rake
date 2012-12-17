namespace :user_import do
  desc "Import users from a CSV file."
  task :csv => :environment do
    require 'csv'
    require 'digest/md5'

    # Example CSV format in the file:
    # UserName,LastName,FirstName,AcademicTitel,PhoneOffice,VoipNr1,VoipNr2,VoipNr3,VoipTelco,CellPhone,HardFax,SoftFax,Email,PIN
    # 123456,Mustermann,Max,Dr.,+49 123 1001234,20,21,22,23,+49 160 12345678,+49 123 1001238,29,max.mustermann@example.com,1324

    # A generic hook to manipulate each given phone number with Ruby tools.
    #
    def regex_convert_phone_numbers(phone_number = nil)
      if phone_number.class == String && !phone_number.blank?
        # 123 Example
        #
        # if !phone_number.match(/^123(..)$/).nil?
        #   phone_number = phone_number.gsub(/^123(..)$/,'123'+$1)
        # end
      end

      phone_number
    end

    # Read the CSV data and store them in the new_users hash.
    #
    csv_data    = CSV.read(IMPORT_CSV_FILE, encoding: IMPORT_CSV_ENCODING)
    headers     = csv_data.shift.map {|i| i.to_s }
    string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
    new_users   = string_data.map {|row| Hash[*headers.zip(row).flatten] }
    gs_node_id  = GsNode.where(:ip_address => HOMEBASE_IP_ADDRESS).first.try(:id)

    if File.exists?(DOUBLE_CHECK_POSITIVE_USERS_CSV)
      csv_data    = CSV.read(DOUBLE_CHECK_POSITIVE_USERS_CSV, encoding: IMPORT_CSV_ENCODING)
      if csv_data.blank?
        double_checked_user_names = []
      else
        headers     = csv_data.shift.map {|i| i.to_s }
        string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
        double_check_positiv_users = string_data.map {|row| Hash[*headers.zip(row).flatten] }

        double_checked_user_names = double_check_positiv_users.map{|user| user['UserName']}
      end
    else
      double_checked_user_names = new_users.map{|user| user['UserName']}
    end

    tenant = Tenant.find(DEFAULT_API_TENANT_ID)

    # Destroy deleted user by making a diff of where(:importer_checksum)
    # and users in the CSV file.
    #
    if defined?(USER_NAME_PREFIX) && !USER_NAME_PREFIX.blank?
      new_users_user_names = new_users.map{|x| USER_NAME_PREFIX.to_s + x['UserName'].to_s}
    else
      new_users_user_names = new_users.map{|x| x['UserName']}
    end
    csv_imported_user_names_in_the_database = User.where('importer_checksum != ?', '').pluck(:user_name)


    to_be_destroyed_user_names = csv_imported_user_names_in_the_database - new_users_user_names

    User.where(:user_name => to_be_destroyed_user_names, :gs_node_id => gs_node_id).destroy_all

    # Loop through all entries in the CSV file.
    #
    new_users.each do |csv_user|
      if !(csv_user['UserName'].blank? || csv_user['Email'].blank?) && double_checked_user_names.include?(csv_user['UserName'])
        csv_user['Email'] = csv_user['Email'].downcase
        if defined?(USER_NAME_PREFIX) && !USER_NAME_PREFIX.blank?
          csv_user['UserName'] = USER_NAME_PREFIX.to_s + csv_user['UserName']
        end

        md5_sum = Digest::MD5.hexdigest(csv_user.to_yaml)
        user = nil

        # Check if this user already exists and has a changed checksum.
        #
        if tenant.users.where(:user_name => csv_user['UserName']).first.try(:importer_checksum).to_s != md5_sum.to_s
          # Find or create the user
          #
          if tenant.users.where(:user_name => csv_user['UserName']).count > 0
            user = tenant.users.where(:user_name => csv_user['UserName']).first
            if defined? IMPORT_IGNORE_PIN_ON_UPDATE && IMPORT_IGNORE_PIN_ON_UPDATE == true
              user.update_attributes(
                :last_name             => csv_user['LastName'],
                :first_name            => csv_user['FirstName'],
                :email                 => csv_user['Email'],
                :importer_checksum     => md5_sum,
                :gs_node_id            => gs_node_id,
              )
            else
              user.update_attributes(              
                :last_name             => csv_user['LastName'],
                :first_name            => csv_user['FirstName'],
                :email                 => csv_user['Email'],
                :new_pin               => csv_user['PIN'],
                :new_pin_confirmation  => csv_user['PIN'],
                :password              => csv_user['PIN'],
                :password_confirmation => csv_user['PIN'],
                :importer_checksum     => md5_sum,
                :gs_node_id            => gs_node_id,
              )
            end
          else
            if csv_user['PIN'].blank?
              csv_user['PIN'] = (1..6).map{|i| (0 .. 9).to_a.sample}.join
            end
            user = tenant.users.create(
              :user_name                          => csv_user['UserName'],
              :last_name                          => csv_user['LastName'],
              :first_name                         => csv_user['FirstName'],
              :email                              => csv_user['Email'],
              :new_pin                            => csv_user['PIN'],
              :new_pin_confirmation               => csv_user['PIN'],
              :password                           => csv_user['PIN'],
              :password_confirmation              => csv_user['PIN'],
              :language_id                        => tenant.language_id,
              :importer_checksum                  => md5_sum,
              :gs_node_id                         => gs_node_id,
              :send_voicemail_as_email_attachment => true,
            )
          end

          # Create group membership
          if tenant.user_groups.exists?(:name => 'Users')
            tenant.user_groups.where(:name => 'Users').first.user_group_memberships.create(:user => user)
          end
        end

        if user
          # Find or create a sip_accounts
          ['VoipNr1', 'VoipNr2', 'VoipNr3'].each_with_index do |phone_number_type, index|
            
            if index > 0 
              auth_name = "#{csv_user['UserName']}_#{index}"
            else
              auth_name = csv_user['UserName'].to_s
            end

            if !phone_number_type.blank? && !csv_user[phone_number_type].blank?
              sip_account = user.sip_accounts.where(:auth_name => auth_name).first
              if sip_account
                if sip_account.caller_name.to_s != user.to_s
                  sip_account.update_attributes(:caller_name => user.to_s)
                end
              else
                sip_account = user.sip_accounts.create(
                  :caller_name   => user.to_s,
                  :voicemail_pin => csv_user['PIN'],
                  :auth_name     => auth_name,
                  :password      => csv_user['PIN'],
                  :clip          => true,
                  :hotdeskable   => true,
                  :callforward_rules_act_per_sip_account => true,
                  :gs_node_id    => gs_node_id,
                  )
              end

              phone_numbers = Array.new()
              phone_numbers.push(csv_user[phone_number_type].to_s.gsub(/[^0-9\+]/, ''))

              # Find or create phone numbers
              converted_phone_number = regex_convert_phone_numbers(csv_user[phone_number_type])
              if converted_phone_number != csv_user[phone_number_type]
                phone_numbers.push(converted_phone_number.gsub(/[^0-9\+]/, ''))
              end
              phone_numbers_count = sip_account.phone_numbers.count
              phone_numbers.each do |phone_number_number|
                phone_number = sip_account.phone_numbers.where(:number => phone_number_number).first
                if !phone_number
                  phone_number = sip_account.phone_numbers.create(:number => phone_number_number, :gs_node_id => gs_node_id)
                end
              end

              # Create default call forwarding entries
              if phone_numbers_count < sip_account.phone_numbers.count
                call_forward_case_offline = CallForwardCase.find_by_value('offline')
                if call_forward_case_offline
                  sip_account.phone_numbers.first.call_forwards.create(:call_forward_case_id => call_forward_case_offline.id, :call_forwardable_type => 'Voicemail', :active => true, :depth => DEFAULT_CALL_FORWARD_DEPTH)
                end
              end
            else
              user.sip_accounts.where(:auth_name => auth_name).destroy_all
            end
          end

          if !csv_user['SoftFax'].blank?
            phone_numbers = Array.new()
            phone_numbers.push(csv_user['SoftFax'].to_s.gsub(/[^0-9\+]/, ''))
            converted_phone_number = regex_convert_phone_numbers(csv_user['SoftFax'])
            if converted_phone_number != csv_user['SoftFax']
              phone_numbers.push(converted_phone_number.gsub(/[^0-9\+]/, ''))
            end

            fax_account = user.fax_accounts.first
            if fax_account
              if fax_account.name != user.to_s || fax_account.email != user.email
                fax_account.update_attributes(:name => user.to_s, :email => user.email)
              end
            else
              fax_account = user.fax_accounts.create(
                :name => user.to_s,
                :station_id => converted_phone_number.gsub(/[^0-9\+]/,''),
                :email => user.email,
                :days_till_auto_delete => 90,
                :retries => 3,
              )
            end

            if fax_account
              fax_account.phone_numbers.each do |phone_number|
                if !phone_numbers.include?(phone_number.number)
                  phone_number.delete
                end
              end
              phone_numbers.each do |phone_number_number|
                phone_number = fax_account.phone_numbers.where(:number => phone_number_number).first
                if !phone_number
                  phone_number = fax_account.phone_numbers.create(:number => phone_number_number)
                end
              end
            end
          else
            user.fax_accounts.destroy_all
          end

          if !csv_user['HardFax'].blank?
            phone_numbers = Array.new()
            phone_numbers.push(csv_user['HardFax'].to_s.gsub(/[^0-9\+]/, ''))
            converted_phone_number = regex_convert_phone_numbers(csv_user['HardFax'])
            if converted_phone_number != csv_user['HardFax']
              phone_numbers.push(converted_phone_number.gsub(/[^0-9\+]/, ''))
            end

            # Create a sip_account for a hardware fax.
            #
            fax_sip_account = user.sip_accounts.where(:description => 'Hardware-Fax').first
            if fax_sip_account
              if fax_sip_account.caller_name != "Hardware Fax of #{user.to_s}"
                fax_sip_account.update_attributes(:caller_name => "Hardware Fax of #{user.to_s}")
              end
            else
              fax_sip_account = user.sip_accounts.create(
                :caller_name => "Hardware Fax of #{user.to_s}",
                :description => 'Hardware-Fax',
                :auth_name     => 'HARDFAX' + csv_user['UserName'],
                :password      => csv_user['PIN'],
                :clip          => true,
                :hotdeskable   => false,
                :callforward_rules_act_per_sip_account => true,
                :gs_node_id    => gs_node_id,
              )
            end

            if fax_sip_account
              fax_sip_account.phone_numbers.each do |phone_number|
                if !phone_numbers.include?(phone_number.number)
                  phone_number.delete
                end
              end
              phone_numbers.each do |phone_number_number|
                phone_number = fax_sip_account.phone_numbers.where(:number => phone_number_number).first
                if !phone_number
                  phone_number = fax_sip_account.phone_numbers.create(:number => phone_number_number)
                end
              end
            end
          else
            user.sip_accounts.where(:description => 'Hardware-Fax').destroy_all
          end

          if !csv_user['VoipTelco'].blank?
            conference = user.conferences.first
            if conference.nil?
              # Create a conference room for this user.
              #
              conference = user.conferences.build
              conference.name = "Default Conference for #{user.to_s}"
              conference.start = nil
              conference.end = nil
              conference.open_for_anybody = true
              conference.max_members = DEFAULT_MAX_CONFERENCE_MEMBERS
              conference.pin = (1..MINIMUM_PIN_LENGTH).map{|i| (0 .. 9).to_a.sample}.join
              conference.save
            end

            phone_numbers = Array.new()
            phone_numbers.push(csv_user['VoipTelco'].to_s.gsub(/[^0-9\+]/, ''))
            converted_phone_number = regex_convert_phone_numbers(csv_user['VoipTelco'])
            if converted_phone_number != csv_user['VoipTelco']
              phone_numbers.push(converted_phone_number.gsub(/[^0-9\+]/, ''))
            end

            if conference
              conference.phone_numbers.each do |phone_number|
                if !phone_numbers.include?(phone_number.number)
                  phone_number.delete
                end
              end
              phone_numbers.each do |phone_number_number|
                phone_number = conference.phone_numbers.where(:number => phone_number_number).first
                if !phone_number
                  phone_number = conference.phone_numbers.create(:number => phone_number_number)
                end
              end
            end
          else
            user.conferences.destroy_all
          end

          # Create Whitelist Entry for default Callthrough
          #
          cell_phone_number = csv_user['CellPhone'].to_s.gsub(/[^0-9\+]/, '')

          if !cell_phone_number.blank?
            callthrough = tenant.callthroughs.find_or_create_by_name(CALLTHROUGH_NAME_TO_BE_USED_FOR_DEFAULT_ACTIVATION)

            access_authorization = callthrough.access_authorizations.find_or_create_by_name('Cellphones')

            new_phone_number = access_authorization.phone_numbers.find_or_create_by_number(cell_phone_number, :name => user.to_s, :access_authorization_user_id => user.id)
          end
        end
      else
        # puts "#{csv_user['UserName']} (#{csv_user['Email']}) has not changed."
      end
    end


  end
end