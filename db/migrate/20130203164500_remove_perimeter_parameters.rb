class StartPerimeterDefense < ActiveRecord::Migration
  def up
    module_index = GsParameter.where(:entity => 'events', :section => 'modules').all.count + 1;
    GsParameter.create(:entity => 'events', :section => 'modules', :name => 'perimeter_defense',  :value => module_index, :class_type => 'Integer')
  end

  def down
  	GsParameter.where(:entity => 'events', :section => 'modules', :name => 'perimeter_defense').destroy_all
  end
end
