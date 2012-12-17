class Call < ActiveRecord::Base
  self.table_name = 'channels'
  self.primary_key = 'uuid'
  
  # Makes sure that this is a readonly model.
  def readonly?
    return true
  end
 
  # Prevent objects from being destroyed
  def before_destroy
    raise ActiveRecord::ReadOnlyRecord
  end

  # Prevent objects from being deleted
  def self.delete_all
    raise ActiveRecord::ReadOnlyRecord
  end

  # Prevent objects from being deleted
  def delete
    raise ActiveRecord::ReadOnlyRecord
  end

  def sip_account
    auth_name = self.name.match('^.+[/:](.+)@.+$')
    if auth_name && ! auth_name[1].blank?
      return SipAccount.where(:auth_name => auth_name[1]).first
    end
  end

  def kill
    require 'freeswitch_event'
    return FreeswitchAPI.execute('uuid_kill', self.uuid, true);
  end
end
