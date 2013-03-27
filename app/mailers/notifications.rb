class Notifications < ActionMailer::Base
  default from: "admin@example.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.notifications.new_pin.subject
  #
  def new_pin(conference)
    @conference = conference

    @pin = Hash.new()
    if conference.conferenceable_type == 'User'
      user = conference.conferenceable
    
      if ! user.first_name.blank?
        @pin[:greeting] = user.first_name
      else
        @pin[:greeting] = user.user_name
      end
    else
      @pin[:greeting] = conference.conferenceable.to_s
    end

    @pin[:conference] = conference.to_s
    @pin[:pin] = conference.pin
    @pin[:phone_numbers] = conference.phone_numbers.join(', ')

    mail(from: Tenant.find(GsParameter.get('DEFAULT_API_TENANT_ID')).from_field_pin_change_email,to: "#{conference.conferenceable.email}", :subject => "Conference PIN changed: #{@pin[:conference]}")
  end

  def new_password(user, password)
    @password = password
    
    @message = Hash.new()
    if ! user.first_name.blank?
      @message[:greeting] = user.first_name
    else
      @message[:greeting] = user.user_name
    end

    mail(from: Tenant.find(GsParameter.get('DEFAULT_API_TENANT_ID')).from_field_pin_change_email, to: "#{user.email}", :subject => "Password recovery")
  end

  def new_voicemail(freeswitch_voicemail_msg, account, email, attach_file = false)
    @voicemail = Hash.new()
    @voicemail[:destination] = freeswitch_voicemail_msg.in_folder
    @voicemail[:from] = "#{freeswitch_voicemail_msg.cid_number} #{freeswitch_voicemail_msg.cid_name}"
    @voicemail[:to] = account.to_s
    @voicemail[:date] = Time.at(freeswitch_voicemail_msg.created_epoch).getlocal.to_s
    @voicemail[:duration] = Time.at(freeswitch_voicemail_msg.message_len).utc.strftime('%T')

    if attach_file
      caller_number = freeswitch_voicemail_msg.cid_number.gsub(/[^0-9]/, '')
      if caller_number.blank?
        caller_number = 'anonymous'
      end
      attachments["#{Time.at(freeswitch_voicemail_msg.created_epoch).getlocal.strftime('%Y%m%d-%H%M%S')}-#{caller_number}.wav"] = File.read(freeswitch_voicemail_msg.file_path)
    end

    mail(from: Tenant.find(GsParameter.get('DEFAULT_API_TENANT_ID')).from_field_voicemail_email, to: email, :subject => "New Voicemail from #{@voicemail[:from]}, received #{Time.at(freeswitch_voicemail_msg.created_epoch).getlocal.to_s}")
  end

  def new_fax(fax_document)
    fax_account = fax_document.fax_account

    if !fax_account || fax_account.email.blank?
      return false
    end

    caller_number = fax_document.caller_id_number.gsub(/[^0-9]/, '')
    if caller_number.blank?
      caller_number = 'anonymous'
    end

    @fax = {
      :greeting => '',
      :account_name => fax_account.name,
      :from => "#{caller_number} #{fax_document.caller_id_name}",
      :remote_station_id => fax_document.remote_station_id,
      :local_station_id => fax_document.local_station_id,
      :date => fax_document.created_at,
    }

    if fax_account.fax_accountable
      if fax_account.fax_accountable_type == 'User'
        user = fax_account.fax_accountable
        if ! user.first_name.blank?
          @fax[:greeting] = user.first_name
        else
          @fax[:greeting] = user.user_name
        end
      elsif fax_account.fax_accountable_type == 'Tenant'
        @fax[:greeting] = fax_account.fax_accountable.name
      end
    end
    attachments["#{fax_document.created_at.strftime('%Y%m%d-%H%M%S')}-#{caller_number}.pdf"] = File.read(fax_document.document.path)
    mail(from: Tenant.find(GsParameter.get('DEFAULT_API_TENANT_ID')).from_field_voicemail_email, to: "#{fax_account.email}", :subject => "New Fax Document from #{@fax[:from]}, received #{fax_document.created_at}")
  end

end
