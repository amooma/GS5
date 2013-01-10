class SetConferenceParameters < ActiveRecord::Migration
  def up
    GsParameter.create(:entity => 'conferences', :section => 'controls_speaker', :name => 'mute',  :value => '', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_speaker', :name => 'deaf mute',  :value => '*', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_speaker', :name => 'energy up',  :value => '9', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_speaker', :name => 'energy equ',  :value => '8', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_speaker', :name => 'energy dn',  :value => '7', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_speaker', :name => 'vol talk up',  :value => '3', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_speaker', :name => 'vol talk zero',  :value => '2', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_speaker', :name => 'vol talk dn',  :value => '1', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_speaker', :name => 'vol listen up',  :value => '6', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_speaker', :name => 'vol listen zero',  :value => '5', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_speaker', :name => 'vol listen dn',  :value => '4', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_speaker', :name => 'hangup',  :value => '#', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_moderator', :name => 'mute',  :value => '0', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_moderator', :name => 'deaf mute',  :value => '*', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_moderator', :name => 'energy up',  :value => '9', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_moderator', :name => 'energy equ',  :value => '8', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_moderator', :name => 'energy dn',  :value => '7', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_moderator', :name => 'vol talk up',  :value => '3', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_moderator', :name => 'vol talk zero',  :value => '2', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_moderator', :name => 'vol talk dn',  :value => '1', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_moderator', :name => 'vol listen up',  :value => '6', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_moderator', :name => 'vol listen zero',  :value => '5', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_moderator', :name => 'vol listen dn',  :value => '4', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'controls_moderator', :name => 'hangup',  :value => '#', :class_type => 'String')
  end

  def down
  	GsParameter.where(:entity => 'conference', :section => 'controls_speaker').destroy_all
    GsParameter.where(:entity => 'conference', :section => 'controls_moderator').destroy_all
  end
end
