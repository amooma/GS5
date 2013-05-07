class AddDisplayIdUnicodeGsParameters < ActiveRecord::Migration
  def up
    GsParameter.create(:entity => 'phones', :section => 'siemens', :name => 'display-id-unicode', :value => '{caller_name}', :class_type => 'String', :description => 'Name shown on the idle screen')
  end

  def down
  	GsParameter.where(:entity => 'phones', :section => 'siemens', :name => 'display-id-unicode').destroy_all
  end
end
