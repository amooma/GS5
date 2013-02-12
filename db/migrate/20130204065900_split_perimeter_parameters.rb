class SplitPerimeterParameters < ActiveRecord::Migration
  def up
    GsParameter.where(:entity => 'perimeter', :section => 'checks').destroy_all
    GsParameter.where(:entity => 'perimeter', :section => 'bad_headers').destroy_all
    GsParameter.create(:entity => 'perimeter', :section => 'general', :name => 'ban_command', :value => 'sudo /sbin/service shorewall refresh', :class_type => 'String', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'checks_register', :name => 'check_frequency', :value => '1', :class_type => 'Integer', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'checks_register', :name => 'check_username_scan', :value => '1', :class_type => 'Integer', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'checks_register', :name => 'check_bad_headers', :value => '1', :class_type => 'Integer', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'checks_call', :name => 'check_frequency', :value => '1', :class_type => 'Integer', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'checks_call', :name => 'check_bad_headers', :value => '1', :class_type => 'Integer', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'bad_headers_register', :name => 'user_agent', :value => '^friendly.scanner$', :class_type => 'String', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'bad_headers_register', :name => 'to_user', :value => '^%d+', :class_type => 'String', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'bad_headers_register', :name => 'auth_result', :value => '^FORBIDDEN$', :class_type => 'String', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'bad_headers_call', :name => 'user_agent', :value => '^friendly.scanner$', :class_type => 'String', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'bad_headers_call', :name => 'hangup_cause', :value => '^MANDATORY_IE_MISSING', :class_type => 'String', :description => '')
  end

  def down
    GsParameter.where(:entity => 'perimeter', :section => 'checks_register').destroy_all
    GsParameter.where(:entity => 'perimeter', :section => 'checks_call').destroy_all
  	GsParameter.where(:entity => 'perimeter', :section => 'bad_headers_register').destroy_all
    GsParameter.where(:entity => 'perimeter', :section => 'bad_headers_call').destroy_all
    GsParameter.create(:entity => 'perimeter', :section => 'checks', :name => 'check_frequency', :value => '1', :class_type => 'Integer', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'checks', :name => 'check_username_scan', :value => '1', :class_type => 'Integer', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'checks', :name => 'check_bad_headers', :value => '1', :class_type => 'Integer', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'bad_headers', :name => 'user_agent', :value => '^friendly.scanner$', :class_type => 'String', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'bad_headers', :name => 'to_user', :value => '^%d+', :class_type => 'String', :description => '')
    GsParameter.create(:entity => 'perimeter', :section => 'bad_headers', :name => 'auth_result', :value => '^FORBIDDEN$', :class_type => 'String', :description => '')
  end
end
