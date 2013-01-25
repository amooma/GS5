class AddDumpVariablesParameter < ActiveRecord::Migration
  def up
    GsParameter.create(:entity => 'dialplan', :section => 'parameters', :name => 'dump_variables',  :value => 'false', :class_type => 'Boolean', :description => 'Log dialplan variables.')
  end

  def down
  	GsParameter.where(:entity => 'dialplan', :section => 'parameters', :name => 'dump_variables').destroy_all
  end
end
