class Call < ActiveRecord::Base
  self.table_name = 'detailed_calls'
  self.primary_key = 'uuid'
  
  def readonly?
    return true
  end

  def destroy
    return self.delete
  end

  def delete
    require 'freeswitch_event'
    return FreeswitchAPI.execute('uuid_kill', self.uuid, true);
  end

  def sip_account
    result = self.presence_id.match('^(.+)@(.+)$')

    if result && ! result[1].blank? and ! result[2].blank?
      domain = SipDomain.where(:host => result[2]).first
      if domain
        return SipAccount.where(:auth_name => result[1], :sip_domain_id => domain.id).first
      end
    end
  end

  def sip_account_bleg
    result = self.b_presence_id.match('^(.+)@(.+)$')

    if result && ! result[1].blank? and ! result[2].blank?
      domain = SipDomain.where(:host => result[2]).first
      if domain
        return SipAccount.where(:auth_name => result[1], :sip_domain_id => domain.id).first
      end
    end
  end

  def get_variable_from_uuid(channel_uuid, variable_name)
    if channel_uuid.blank? 
      return nil
    end

    require 'freeswitch_event'
    result = FreeswitchAPI.channel_variable_get(channel_uuid, variable_name);

    if result == '_undef_'
      return nil
    end

    return result
  end

  def get_variable(variable_name)
    return get_variable_from_uuid(self.uuid, variable_name);
  end

  def get_variable_bleg(variable_name)
    return get_variable_from_uuid(self.b_uuid, variable_name);
  end

  def is_sip
    return self.name.match('^sofia') != nil
  end

  def is_caller
    if (self.uuid == self.call_uuid) || self.call_uuid.blank?
      true
    end 
  end
end
