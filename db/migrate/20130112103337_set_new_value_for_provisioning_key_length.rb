class SetNewValueForProvisioningKeyLength < ActiveRecord::Migration
  def up
    GsParameter.create(:entity => nil, :section => 'Provisioning', :name => 'PROVISIONING_KEY_LENGTH',  :value => '12', :class_type => 'Integer')
  end

  def down
    GsParameter.where(:name => 'PROVISIONING_KEY_LENGTH').destroy_all
  end
end
