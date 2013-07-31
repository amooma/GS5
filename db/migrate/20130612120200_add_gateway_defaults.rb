class AddGatewayDefaults < ActiveRecord::Migration
  def up
    GsParameter.create(:entity => 'sip_gateways', :section => 'settings', :name => 'domain',  :value => '192.168.1.1', :class_type => 'String')
    GsParameter.create(:entity => 'sip_gateways', :section => 'settings', :name => 'auth_source',  :value => 'sip_received_ip', :class_type => 'String')
    GsParameter.create(:entity => 'sip_gateways', :section => 'settings', :name => 'auth_pattern',  :value => '^192.168.1.1$', :class_type => 'String')
    GsParameter.create(:entity => 'sip_gateways', :section => 'settings', :name => 'from',  :value => '"{caller_id_name}" <sip:{caller_id_number}@{domain_local}>', :class_type => 'String')
    GsParameter.create(:entity => 'sip_gateways', :section => 'settings', :name => 'from_clir',  :value => '"Anonymous" <sip:anonymous@{domain_local}>', :class_type => 'String')
    GsParameter.create(:entity => 'sip_gateways', :section => 'settings', :name => 'asserted_identity',  :value => '"{caller_id_name}" <sip:{caller_id_number}@{domain_local}>', :class_type => 'String')
    GsParameter.create(:entity => 'sip_gateways', :section => 'settings', :name => 'asserted_identity_clir',  :value => '"Anonymous" <sip:{caller_id_number}@{domain_local}>', :class_type => 'String')
  end

  def down
    GsParameter.where(:entity => 'sip_gateways', :section => 'settings').destroy_all
  end
end
