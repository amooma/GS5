class ChangeConferenceParameters < ActiveRecord::Migration
  def up
    GsParameter.where(:entity => 'conferences', :section => 'parameters').destroy_all
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'caller-controls',  :value => 'speaker', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'moderator-controls',  :value => 'moderator', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'muted-sound',  :value => 'conference/conf-muted.wav', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'unmuted-sound',  :value => 'conference/conf-unmuted.wav', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'moh-sound',  :value => '', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'comfort-noise',  :value => 'true', :class_type => 'Boolean')
  end

  def down
  	GsParameter.where(:entity => 'conferences', :section => 'parameters').destroy_all
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'caller-controls',  :value => 'speaker', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'moderator-controls',  :value => 'moderator', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'max-members',  :value => 100, :class_type => 'Integer')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'rate',  :value => 16000, :class_type => 'Integer')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'interval',  :value => 20, :class_type => 'Integer')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'energy-level',  :value => 300, :class_type => 'Integer')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'sound-prefix',  :value => '/opt/freeswitch/sounds/de/tts/google', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'muted-sound',  :value => 'conference/conf-muted.wav', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'unmuted-sound',  :value => 'conference/conf-unmuted.wav', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'alone-sound',  :value => 'conference/conf-alone.wav', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'moh-sound',  :value => 'local_stream://moh', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'enter-sound',  :value => 'tone_stream://%(200,0,500,600,700)', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'exit-sound',  :value => 'tone_stream://%(500,0,300,200,100,50,25)', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'kicked-sound',  :value => 'conference/conf-kicked.wav', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'locked-sound',  :value => 'conference/conf-locked.wav', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'is-locked-sound',  :value => 'conference/conf-is-locked.wav', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'is-unlocked-sound',  :value => 'conference/conf-is-unlocked.wav', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'pin-sound',  :value => 'conference/conf-pin.wav', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'bad-pin-sound',  :value => 'conference/conf-bad-pin.wav', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'caller-id-name',  :value => 'Conference', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'caller-id-number',  :value => '', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'comfort-noise',  :value => 'true', :class_type => 'Boolean')
  end
end
