class FreeswitchInterface < ActiveRecord::Base
  self.table_name = 'interfaces'

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
