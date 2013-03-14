class AddEventSocketGsParameters < ActiveRecord::Migration
  def up
    GsParameter.create(:entity => 'event_socket', :section => 'settings', :name => 'listen-ip', :value => '127.0.0.1', :class_type => 'String', :description => '')
    GsParameter.create(:entity => 'event_socket', :section => 'settings', :name => 'listen-port', :value => '8021', :class_type => 'Integer', :description => '')
    GsParameter.create(:entity => 'event_socket', :section => 'settings', :name => 'password', :value => 'ClueCon', :class_type => 'String', :description => '')
  end

  def down
  	GsParameter.where(:entity => 'event_socket', :section => 'settings').destroy_all
  end
end
