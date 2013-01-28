class AddDingalingParameter < ActiveRecord::Migration
  def up
    GsParameter.create(:entity => 'dingaling', :section => 'parameters', :name => 'debug',  :value => '0', :class_type => 'Integer', :description => 'Debug level.')
    GsParameter.create(:entity => 'dingaling', :section => 'parameters', :name => 'codec-prefs',  :value => 'PCMA,PCMU', :class_type => 'String', :description => 'Codec preferences.')
  end

  def down
  	GsParameter.where(:entity => 'dingaling', :section => 'parameters').destroy_all
  end
end
