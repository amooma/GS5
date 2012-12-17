class AddProvisioningKeyActiveToPhones < ActiveRecord::Migration
  def change
    add_column :phones, :provisioning_key_active, :boolean

  end
end
