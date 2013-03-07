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
