namespace :gs_cluster do
  desc "Sync local data to other gs cluster nodes."
  task :push_waiting_data_to_other_nodes => :environment do
    infinity_loop_protection_counter = GsClusterSyncLogEntry.where(:homebase_ip_address => GsParameter.get('HOMEBASE_IP_ADDRESS'), 
    	                                                           :waiting_to_be_synced => true).count + 10

    # One bite at a time.
    #
    while GsClusterSyncLogEntry.where(:homebase_ip_address => GsParameter.get('HOMEBASE_IP_ADDRESS'), 
    	                                :waiting_to_be_synced => true).any? && 
                                      infinity_loop_protection_counter > 0
      GsClusterSyncLogEntry.where(:homebase_ip_address => GsParameter.get('HOMEBASE_IP_ADDRESS'), 
      	                          :waiting_to_be_synced => true).first.populate_other_cluster_nodes
      infinity_loop_protection_counter -= 1
    end

  end

  desc "Reset gs_cluster_sync_log."
  task :reset_sync_log => :environment do
    GsClusterSyncLogEntry.destroy_all

    User.where('is_native IS NOT FALSE').each do |user|
      puts("Processing User=#{user.id}/#{user.uuid} - #{user.user_name}")
      user.create_on_other_gs_nodes
    end

    SipAccount.where('is_native IS NOT FALSE').each do |sip_account|
      puts("Processing SipAccount=#{sip_account.id}/#{sip_account.uuid} - #{sip_account.auth_name}");
      sip_account.create_on_other_gs_nodes
    end

    PhoneNumber.where('is_native IS NOT FALSE AND phone_numberable_type IN ("SipAccount", "Conference", "FaxAccount", "Callthrough", "HuntGroup", "AutomaticCallDistributor")').each do |phone_number|
      puts("Processing PhoneNumber=#{phone_number.id}/#{phone_number.uuid} - #{phone_number.number}");
      phone_number.create_on_other_gs_nodes
    end
  end

  desc "Pull objects from nodes."
  task :pull => :environment do
    local_node = GsNode.where(:ip_address => GsParameter.get('HOMEBASE_IP_ADDRESS')).first
    GsNode.where(:accepts_updates_from => true).each do |remote_node|
      if remote_node.id == local_node.id
        next
      end

      puts "Processing node: #{remote_node.name}"
      pull_node(remote_node, local_node)
    end
  end

  def pull_node(remote_node, local_node)
    require 'nokogiri'
    require 'open-uri'

    is_native = false
    remote_site = remote_node.site
    local_node_id = local_node.id
    last_sync = remote_node.last_sync.to_i

    remote_objects(remote_site, local_node_id, last_sync, Tenant).each do |tenant|
      puts "Processing Tenant: #{tenant[:name]}"
    end

    remote_objects(remote_site, local_node_id, last_sync, UserGroup).each do |remote_object|
      attributes = make_hash(remote_object.attributes)
      tenant = Tenant.where(:name => attributes[:tenant]).first
      process_object(UserGroup, tenant.user_groups, UserGroup.where(:name => attributes[:name], :tenant_id => tenant.try(:id)).first, attributes)
    end

    remote_objects(remote_site, local_node_id, last_sync, User).each do |remote_object|
      attributes = make_hash(remote_object.attributes)

      tenant = Tenant.where(:name => attributes[:current_tenant]).first
      attributes[:language_id] = Language.where(:code => attributes[:language]).first.try(:id)
      attributes.delete(:language)
      attributes.delete(:current_tenant)

      if tenant
        if ! attributes[:gs_node].blank?
          attributes[:gs_node_id] = GsNode.where(:name => attributes[:gs_node]).first.try(:id)
          attributes.delete(:gs_node)
        end

        process_object(User, tenant.users, User.where(:uuid => attributes[:uuid]).first, attributes, { :is_native => is_native })
      else
        $stderr.puts "NO_PROCESSING User #{attributes[:uuid]} - no current tenant"
      end
    end

    remote_objects(remote_site, local_node_id, last_sync, UserGroupMembership).each do |remote_object|
      attributes = make_hash(remote_object.attributes)
      attributes[:user_id] = User.where(:uuid => attributes[:user_uuid]).first.try(:id)
      attributes[:user_group_id] = UserGroup.where(:name => attributes[:user_group]).first.try(:id)
      attributes.delete(:user_uuid)
      attributes.delete(:user_group)

      if attributes[:user_id] && attributes[:user_group_id]
        process_object(UserGroupMembership, UserGroupMembership, UserGroupMembership.where(:user_id => attributes[:user_id], :user_group_id => attributes[:user_group_id]).first, attributes)
      end
    end

    remote_objects(remote_site, local_node_id, last_sync, SipAccount).each do |remote_object|
      attributes = make_hash(remote_object.attributes)
      attributes[:tenant_id] = Tenant.where(:name => attributes[:tenant]).first.try(:id)
      attributes[:sip_domain] = SipDomain.where(:host => attributes[:sip_domain]).first
      
      if ! attributes[:sip_accountable_uuid].blank?
        attributes[:sip_accountable_id] = attributes[:sip_accountable_type].constantize.where(:uuid => attributes[:sip_accountable_uuid]).first.try(:id)
      end

      if attributes[:sip_accountable_id]
        if ! attributes[:gs_node].blank?
          attributes[:gs_node_id] = GsNode.where(:name => attributes[:gs_node]).first.try(:id)
          attributes.delete(:gs_node)
        end

        attributes.delete(:sip_accountable_uuid)
        attributes.delete(:tenant)
        process_object(SipAccount, SipAccount, SipAccount.where(:uuid => attributes[:uuid]).first, attributes, { :is_native => is_native })
      end
    end

    remote_objects(remote_site, local_node_id, last_sync, Conference).each do |remote_object|
      attributes = make_hash(remote_object.attributes)

      if ! attributes[:conferenceable_uuid].blank?
        attributes[:conferenceable_id] = attributes[:conferenceable_type].constantize.where(:uuid => attributes[:conferenceable_uuid]).first.try(:id)
      end
      attributes.delete(:conferenceable_uuid)

      process_object(Conference, Conference, Conference.where(:uuid => attributes[:uuid]).first, attributes)
    end

    remote_objects(remote_site, local_node_id, last_sync, FaxAccount).each do |remote_object|
      attributes = make_hash(remote_object.attributes)
      attributes[:tenant_id] = Tenant.where(:name => attributes[:tenant]).first.try(:id)
      if ! attributes[:fax_accountable_uuid].blank?
        attributes[:fax_accountable_id] = attributes[:fax_accountable_type].constantize.where(:uuid => attributes[:fax_accountable_uuid]).first.try(:id)
      end
      attributes.delete(:fax_accountable_uuid)
      attributes.delete(:tenant)
      process_object(FaxAccount, FaxAccount, FaxAccount.where(:uuid => attributes[:uuid]).first, attributes)
    end

    remote_objects(remote_site, local_node_id, last_sync, PhoneBook).each do |remote_object|
      attributes = make_hash(remote_object.attributes)

      if ! attributes[:phone_bookable_uuid].blank?
        attributes[:phone_bookable_id] = attributes[:phone_bookable_type].constantize.where(:uuid => attributes[:phone_bookable_uuid]).first.try(:id)
      end
      attributes.delete(:phone_bookable_uuid)
      process_object(PhoneBook, PhoneBook, PhoneBook.where(:uuid => attributes[:uuid]).first, attributes)
    end

    remote_objects(remote_site, local_node_id, last_sync, PhoneBookEntry).each do |remote_object|
      attributes = make_hash(remote_object.attributes)
      attributes[:phone_book_id] = PhoneBook.where(:uuid => attributes[:phone_book_uuid]).first.try(:id)
      attributes.delete(:phone_book_uuid)
      process_object(PhoneBookEntry, PhoneBookEntry, PhoneBookEntry.where(:uuid => attributes[:uuid]).first, attributes)
    end

    remote_objects(remote_site, local_node_id, last_sync, PhoneNumber).each do |remote_object|
      attributes = make_hash(remote_object.attributes)

      if ! attributes[:phone_numberable_uuid].blank?
        attributes[:phone_numberable_id] = attributes[:phone_numberable_type].constantize.where(:uuid => attributes[:phone_numberable_uuid]).first.try(:id)
      end

      if ! attributes[:gs_node].blank?
        attributes[:gs_node_id] = GsNode.where(:name => attributes[:gs_node]).first.try(:id)
        attributes.delete(:gs_node)
      end

      if !attributes[:phone_numberable_id]
        puts "WARNING PhoneNumber #{attributes[:number]} has no local parent object #{attributes[:phone_numberable_type]}/#{attributes[:phone_numberable_uuid]}"
      end

      attributes.delete(:phone_numberable_uuid)
      process_object(PhoneNumber, PhoneNumber, PhoneNumber.where(:uuid => attributes[:uuid]).first, attributes, { :is_native => is_native })
    end

    remote_objects(remote_site, local_node_id, last_sync, CallForward).each do |remote_object|
      attributes = make_hash(remote_object.attributes)

      attributes[:phone_number_id] = PhoneNumber.where(:uuid => attributes[:phone_number_uuid]).first.try(:id)
      
      if ! attributes[:call_forwardable_uuid].blank?
        attributes[:call_forwardable_id] = attributes[:call_forwardable_type].constantize.where(:uuid => attributes[:call_forwardable_uuid]).first.try(:id)
        attributes.delete(:call_forwardable_uuid)
      end

      attributes[:call_forward_case_id] = CallForwardCase.where(:value => attributes[:service]).first.try(:id)
      
      attributes.delete(:phone_number_uuid)
      attributes.delete(:service)

      process_object(CallForward, CallForward, CallForward.where(:uuid => attributes[:uuid]).first, attributes)
    end

    remote_objects(remote_site, local_node_id, last_sync, Softkey).each do |remote_object|
      attributes = make_hash(remote_object.attributes)
      attributes[:sip_account_id] = SipAccount.where(:uuid => attributes[:sip_account_uuid]).first.try(:id)
      attributes[:call_forward_id] = CallForward.where(:uuid => attributes[:call_forward_uuid]).first.try(:id)
      attributes[:softkey_function_id] = SoftkeyFunction.where(:name => attributes[:function]).first.try(:id)
      attributes.delete(:sip_account_uuid)
      attributes.delete(:call_forward_uuid)
      attributes.delete(:softkey_function)
      process_object(Softkey, Softkey, Softkey.where(:uuid => attributes[:uuid]).first, attributes)
    end

    remote_objects(remote_site, local_node_id, last_sync, Ringtone).each do |remote_object|
      attributes = make_hash(remote_object.attributes)
      if ! attributes[:ringtoneable_uuid].blank?
        attributes[:ringtoneable_id] = attributes[:ringtoneable_type].constantize.where(:uuid => attributes[:ringtoneable_uuid]).first.try(:id)
      end

      if !attributes[:ringtoneable_id]
        puts "WARNING Ringtone #{attributes[:number]} has no local parent object #{attributes[:ringtoneable_type]}/#{attributes[:ringtoneable_uuid]}"
      else
        attributes.delete(:ringtoneable_uuid)
        process_object(Ringtone, Ringtone, Ringtone.where(:ringtoneable_type => attributes[:ringtoneable_type], :ringtoneable_id => attributes[:ringtoneable_id]).first, attributes)
      end
    end

    remote_objects(remote_site, local_node_id, last_sync, ConferenceInvitee).each do |remote_object|
      attributes = make_hash(remote_object.attributes)
      attributes[:conference_id] = Conference.where(:uuid => attributes[:conference_uuid]).first.try(:id)
      attributes[:phone_number] = PhoneNumber.where(:uuid => attributes[:phone_number_uuid]).first
      if !attributes[:conference_id]
        puts "WARNING ConferenceInvitee #{attributes[:uuid]} has no local Conference object #{attributes[:conference_uuid]}"
      else
        attributes[:phone_book_entry_id] = PhoneBookEntry.where(:uuid => attributes[:phone_book_entry_uuid]).first.try(:id)
        attributes.delete(:conference_uuid)
        attributes.delete(:phone_number_uuid)
        attributes.delete(:phone_book_entry_uuid)
        process_object(ConferenceInvitee, ConferenceInvitee, ConferenceInvitee.where(:uuid => attributes[:uuid]).first, attributes)
      end
    end

    #remote_objects(remote_site, local_node_id, last_sync, FaxDocument).each do |remote_object|
    #  attributes = make_hash(remote_object.attributes)
    #  attributes[:fax_account_id] = FaxAccount.where(:uuid => attributes[:fax_account_uuid]).first.try(:id)
    #  attributes[:fax_resolution_id] = FaxResolution.where(:resolution_value => attributes[:fax_resolution]).first.try(:id)
    #  attributes.delete(:fax_account_uuid)
    # attributes.delete(:fax_resolution)
    #  process_object(FaxDocument, FaxDocument, FaxDocument.where(:uuid => attributes[:uuid]).first, attributes)
    #end

    #remote_objects(remote_site, local_node_id, last_sync, CallHistory).each do |remote_object|
    #  attributes = make_hash(remote_object.attributes)
    #  process_object(CallHistory, CallHistory, CallHistory.where(:caller_channel_uuid => attributes[:caller_channel_uuid], :call_historyable_type => attributes[:caller_channel_type], :call_historyable_id => call_historyable.try(:id)).first, attributes)
    #end

    remote_objects(remote_site, local_node_id, last_sync, DeletedItem).each do |remote_object|
      attributes = make_hash(remote_object.attributes)
      deleted_item = remote_object[:class_name].constantize.where(:uuid => attributes[:uuid]).first

      if deleted_item
        print "DELETE #{deleted_item.class.to_s} #{deleted_item.to_s} : "

        if deleted_item.destroy
          puts "OK"
        else
          $stderr.puts "Couldn't delete #{deleted_item.class.to_s}. #{deleted_item.errors.inspect}"
        end
      else
        puts "NO_DELETE #{remote_object[:class_name]} #{remote_object[:uuid]}"
      end
    end

    if ! remote_node.synced
      $stderr.puts "Errors updating node #{remote_node.name}. #{remote_node.errors.inspect}"
    end
  end

  def make_hash(attributes, new_hash = Hash.new)
    attributes.each do |key, value|
      new_hash[key.to_sym] = value.to_s
    end
    return new_hash
  end

  def remote_objects(remote_site, local_node_id, last_sync, object_class)
    class_name = object_class.to_s.underscore
    section_name = class_name.pluralize    
    doc = Nokogiri::XML(open("#{remote_site}/gs_nodes/#{local_node_id}/sync.xml?newer=#{last_sync}&image=false&class=#{section_name}", :proxy => nil, :read_timeout => 120))
    return doc.xpath("//gemeinschaft_sync/#{section_name}/#{class_name}")
  end

  def process_object(object_class, belongs_to, local_object, attributes, local_attributes = Hash.new)
    if local_object
      if local_object.updated_at < attributes[:updated_at]
        print "UPDATE #{object_class.to_s} #{local_object.to_s} : "
        update_object(local_object, attributes, local_attributes)
      else
        print "NO_UPDATE #{object_class.to_s}: #{local_object.to_s} - last update: #{local_object.updated_at}, remote: #{attributes[:updated_at]}"
      end
    else
      print "CREATE #{object_class.to_s} #{attributes[:name].to_s} #{attributes[:uuid].to_s} : "
      create_object(belongs_to, attributes, local_attributes)
    end
    puts "."
  end

  def create_object(object_class, attributes, local_attributes)
    attributes = attributes.merge(local_attributes)

    new_local_copy = object_class.create(attributes, :without_protection => true)
    if new_local_copy && new_local_copy.errors.count == 0
      print "Created object, #{new_local_copy.class.to_s} #{new_local_copy.to_s}"
      return true
    else
      $stderr.print "Couldn't create object. #{new_local_copy.errors.messages.inspect}"
      return false
    end
  end

  def update_object(local_object, attributes, local_attributes)
    attributes = attributes.merge(local_attributes)

    if local_object.update_attributes(attributes, :without_protection => true)
      print "Updated #{local_object.class.to_s}, ID #{local_object.id}."
      return true
    else
      $stderr.print "Couldn't update UserGroup. #{local_user_group.errors.inspect}"
      return true
    end
  end

  class DeletedItem
  end
end
