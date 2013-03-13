class Call < ActiveRecord::Base
  self.table_name = 'calls_active'
  self.primary_key = 'uuid'

  belongs_to :sip_account
  belongs_to :b_sip_account, :class_name => SipAccount

  validates :sip_account_id,
            :presence => true

  validates :destination,
            :presence => true
  
  def save(attributes=nil) 
  end

  def call
    if self.sip_account && self.destination
      return self.sip_account.call(self.destination)
    end

    if !self.sip_account
      errors.add(:sip_account_id, 'no sip_account')
    end

    if self.destination.blank?
      errors.add(:destination, 'no destination')
    end

    return false
  end

  def destroy
    return self.delete
  end

  def delete
    require 'freeswitch_event'
    return FreeswitchAPI.execute('uuid_kill', self.uuid, true);
  end

  def transfer_blind(destination, call_leg=:aleg, auth_account=nil)
    if destination.blank?
      return nil
    end

    if call_leg == :bleg
      channel_uuid = self.b_uuid
    else
      channel_uuid = self.uuid
    end

    if channel_uuid.blank?
      return nil
    end

    if auth_account 
      FreeswitchAPI.api('uuid_setvar', channel_uuid, 'gs_auth_account_type', auth_account.class.name)
      FreeswitchAPI.api('uuid_setvar', channel_uuid, 'gs_auth_account_uuid', auth_account.uuid)
    end

    require 'freeswitch_event'
    return FreeswitchAPI.api_result(FreeswitchAPI.api('uuid_transfer', channel_uuid, destination))
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
  
end
