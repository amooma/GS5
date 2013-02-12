class DefaultProfileToTemplate < ActiveRecord::Migration
  def up
    GsParameter.where(:entity => 'sofia', :section => 'profile:gemeinschaft').each do |profile|
      profile.update_attributes(:section => 'profile')
    end
  end

  def down
  	GsParameter.where(:entity => 'sofia', :section => 'profile').each do |profile|
      profile.update_attributes(:section => 'profile:gemeinschaft')
    end
  end
end
