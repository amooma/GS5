class AddSoundsToParameters < ActiveRecord::Migration
  def up
    GsParameter.create(:entity => 'dialplan', :section => 'sounds', :name => 'en',  :value => '/opt/freeswitch/sounds/en/us/callie', :class_type => 'String')
    GsParameter.create(:entity => 'dialplan', :section => 'sounds', :name => 'de',  :value => '/opt/freeswitch/sounds/de/de/callie', :class_type => 'String')
  end

  def down
    GsParameter.where(:entity => 'dialplan', :section => 'sounds').destroy_all
  end
end
