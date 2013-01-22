class ChangeUserNamePrefix < ActiveRecord::Migration
  def up
	  GsParameter.where(:name => 'USER_NAME_PREFIX').first.update_attributes(:value => "xyz")
  end
end
