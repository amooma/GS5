class SetProvisioningSetHttpUser < ActiveRecord::Migration
  def up
    # Provisioning stuff
    #
    GsParameter.create(:name => 'PROVISIONING_SET_HTTP_USER', :section => 'Provisioning', :value => 'admin', :class_type => 'String')
    GsParameter.create(:name => 'PROVISIONING_SET_HTTP_PASSWORD', :section => 'Provisioning', :value => '8', :class_type => 'Integer')
  end

  def down
  	GsParameter.where(:name => 'PROVISIONING_SET_HTTP_USER').destroy_all
  	GsParameter.where(:name => 'PROVISIONING_SET_HTTP_PASSWORD').destroy_all
  end
end
