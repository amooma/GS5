class FreeswitchCall < ActiveRecord::Base
  self.table_name = 'calls'
  self.primary_key = 'call_uuid'
  
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
end
