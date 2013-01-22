class SetDialplanVariables < ActiveRecord::Migration
  def up
    GsParameter.create(:entity => 'dialplan', :section => 'variables', :name => 'ringback',  :value => '%(2000,4000,440.0,480.0)', :class_type => 'String')
    GsParameter.create(:entity => 'dialplan', :section => 'variables', :name => 'send_silence_when_idle',  :value => 0, :class_type => 'Integer')
    GsParameter.create(:entity => 'dialplan', :section => 'variables', :name => 'hold_music',  :value => 'local_stream://moh', :class_type => 'String')
  end

  def down
  	GsParameter.where(:entity => 'dialplan', :section => 'variables').destroy_all
  end
end
