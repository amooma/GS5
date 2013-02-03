class RemovePerimeterParameters < ActiveRecord::Migration
  def up
    GsParameter.where(:entity => 'perimeter', :section => 'general', :name => 'malicious_contact_count').destroy_all
    GsParameter.where(:entity => 'perimeter', :section => 'general', :name => 'malicious_contact_time_span').destroy_all
    GsParameter.where(:entity => 'perimeter', :section => 'general', :name => 'ban_futile').destroy_all
    GsParameter.where(:entity => 'perimeter', :section => 'general', :name => 'execute').destroy_all

  end

  def down
  	GsParameter.create(:entity => 'perimeter', :section => 'general', :name => 'malicious_contact_count',  :value => 20, :class_type => 'Integer')
    GsParameter.create(:entity => 'perimeter', :section => 'general', :name => 'malicious_contact_time_span',  :value => 2, :class_type => 'Integer')
    GsParameter.create(:entity => 'perimeter', :section => 'general', :name => 'ban_futile',  :value => 5, :class_type => 'Integer')
    GsParameter.create(:entity => 'perimeter', :section => 'general', :name => 'execute',  :value => 'sudo /usr/local/bin/ban_ip.sh {ip_address}', :class_type => 'String')
  end
end
