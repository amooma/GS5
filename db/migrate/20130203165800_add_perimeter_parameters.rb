class AddPerimeterParameters < ActiveRecord::Migration
  def up
    GsParameter.create(:entity => 'perimeter', :section => 'general', :name => 'contact_count_threshold', :value => '10', :class_type => 'Integer', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'general', :name => 'contact_span_threshold', :value => '2', :class_type => 'Integer', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'general', :name => 'name_changes_threshold', :value => '5', :class_type => 'Integer', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'general', :name => 'ban_threshold', :value => '20', :class_type => 'Integer', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'general', :name => 'ban_tries', :value => '1', :class_type => 'Integer', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'general', :name => 'blacklist_file', :value => '/var/opt/gemeinschaft/firewall/blacklist', :class_type => 'String', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'general', :name => 'blacklist_file_comment', :value => '# PERIMETER_BAN - points: {points}, generated: {date}', :class_type => 'String', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'general', :name => 'blacklist_file_entry', :value => '{received_ip} udp 5060', :class_type => 'String', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'general', :name => 'ban_command', :value => 'sudo /sbin/service shorewall refresh', :class_type => 'String', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'checks', :name => 'check_frequency', :value => '1', :class_type => 'Integer', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'checks', :name => 'check_username_scan', :value => '1', :class_type => 'Integer', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'checks', :name => 'check_bad_headers', :value => '1', :class_type => 'Integer', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'bad_headers', :name => 'user_agent', :value => '^friendly.scanner$', :class_type => 'String', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'bad_headers', :name => 'to_user', :value => '^%d+', :class_type => 'String', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'bad_headers', :name => 'auth_result', :value => '^FORBIDDEN$', :class_type => 'String', :description => '')
  end

  def down
  	GsParameter.where(:entity => 'perimeter').destroy_all
  end
end
