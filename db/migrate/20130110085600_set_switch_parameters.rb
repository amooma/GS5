class SetSwitchParameters < ActiveRecord::Migration
  def up
    GsParameter.create(:entity => 'post_load_switch', :section => 'settings', :name => 'loglevel',  :value => 'debug', :class_type => 'String')
    GsParameter.create(:entity => 'post_load_switch', :section => 'settings', :name => 'colorize-console',  :value => 'true', :class_type => 'Boolean')
    GsParameter.create(:entity => 'post_load_switch', :section => 'settings', :name => 'max-sessions',  :value => 1000, :class_type => 'Integer')
    GsParameter.create(:entity => 'post_load_switch', :section => 'settings', :name => 'sessions-per-second',  :value => 30, :class_type => 'Integer')
    GsParameter.create(:entity => 'post_load_switch', :section => 'settings', :name => 'rtp-enable-zrtp',  :value => 'false', :class_type => 'Boolean')
    GsParameter.create(:entity => 'post_load_switch', :section => 'settings', :name => 'rtp-start-port',  :value => 16384, :class_type => 'Integer')
    GsParameter.create(:entity => 'post_load_switch', :section => 'settings', :name => 'rtp-end-port',  :value => 32768, :class_type => 'Integer')
  end

  def down
  	GsParameter.where(:entity => 'post_load_switch', :section => 'settings', :name => 'loglevel').destroy_all
    GsParameter.where(:entity => 'post_load_switch', :section => 'settings', :name => 'colorize-console').destroy_all
    GsParameter.where(:entity => 'post_load_switch', :section => 'settings', :name => 'max-sessions').destroy_all
    GsParameter.where(:entity => 'post_load_switch', :section => 'settings', :name => 'sessions-per-second').destroy_all
    GsParameter.where(:entity => 'post_load_switch', :section => 'settings', :name => 'rtp-enable-zrtp').destroy_all
    GsParameter.where(:entity => 'post_load_switch', :section => 'settings', :name => 'rtp-start-port').destroy_all
    GsParameter.where(:entity => 'post_load_switch', :section => 'settings', :name => 'rtp-end-port').destroy_all
  end
end
