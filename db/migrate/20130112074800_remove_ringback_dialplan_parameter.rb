class RemoveRingbackDialplanParameter < ActiveRecord::Migration
  def up
    GsParameter.where(:entity => 'dialplan', :section => 'parameters', :name => 'ringback').destroy_all
  end

  def down
    GsParameter.create(:entity => 'dialplan', :section => 'parameters', :name => 'ringback',  :value => '%(2000,4000,440.0,480.0)', :class_type => 'String')
  end
end
