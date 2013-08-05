class AddGatewayDefaultHeaders < ActiveRecord::Migration
  def up
    GsParameter.where(:entity => 'sip_gateways', :section => 'settings', :name => 'from').destroy_all
    GsParameter.where(:entity => 'sip_gateways', :section => 'settings', :name => 'from_clir').destroy_all
    GsParameter.where(:entity => 'sip_gateways', :section => 'settings', :name => 'asserted_identity').destroy_all
    GsParameter.where(:entity => 'sip_gateways', :section => 'settings', :name => 'asserted_identity_clir').destroy_all

    GsParameter.create(:entity => 'sip_gateways', :section => 'settings', :name => 'dtmf_type',  :value => 'rfc2833', :class_type => 'String')

    GsParameter.create(:entity => 'sip_gateways', :section => 'headers_default', :name => 'INVITE',  :value => '"sip:{destination_number}@{domain}', :class_type => 'String')
    GsParameter.create(:entity => 'sip_gateways', :section => 'headers_default', :name => 'To',  :value => '<sip:{destination_number}@{domain}>', :class_type => 'String')
    GsParameter.create(:entity => 'sip_gateways', :section => 'headers_default_clir_off', :name => 'From',  :value => '"{caller_id_name}" <sip:{caller_id_number}@{domain_local}>', :class_type => 'String')
    GsParameter.create(:entity => 'sip_gateways', :section => 'headers_default_clir_on', :name => 'From',  :value => '"Anonymous" <sip:anonymous@{domain_local}>', :class_type => 'String')
    GsParameter.create(:entity => 'sip_gateways', :section => 'headers_default_clir_off', :name => 'P-Asserted-Identity',  :value => '"{caller_id_name}" <sip:{caller_id_number}@{domain_local}>', :class_type => 'String')
    GsParameter.create(:entity => 'sip_gateways', :section => 'headers_default_clir_on', :name => 'P-Asserted-Identity',  :value => '"Anonymous" <sip:{caller_id_number}@{domain_local}>', :class_type => 'String')
    GsParameter.create(:entity => 'sip_gateways', :section => 'headers_default_clir_on', :name => 'Privacy',  :value => 'id', :class_type => 'String')
  end

  def down
    GsParameter.create(:entity => 'sip_gateways', :section => 'settings', :name => 'domain',  :value => '192.168.1.1', :class_type => 'String')
    GsParameter.create(:entity => 'sip_gateways', :section => 'settings', :name => 'auth_source',  :value => 'sip_received_ip', :class_type => 'String')
    GsParameter.create(:entity => 'sip_gateways', :section => 'settings', :name => 'auth_pattern',  :value => '^192.168.1.1$', :class_type => 'String')
    GsParameter.create(:entity => 'sip_gateways', :section => 'settings', :name => 'from',  :value => '"{caller_id_name}" <sip:{caller_id_number}@{domain_local}>', :class_type => 'String')
    GsParameter.create(:entity => 'sip_gateways', :section => 'settings', :name => 'from_clir',  :value => '"Anonymous" <sip:anonymous@{domain_local}>', :class_type => 'String')
    GsParameter.create(:entity => 'sip_gateways', :section => 'settings', :name => 'asserted_identity',  :value => '"{caller_id_name}" <sip:{caller_id_number}@{domain_local}>', :class_type => 'String')
    GsParameter.create(:entity => 'sip_gateways', :section => 'settings', :name => 'asserted_identity_clir',  :value => '"Anonymous" <sip:{caller_id_number}@{domain_local}>', :class_type => 'String')
  end
end
