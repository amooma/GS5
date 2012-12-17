class AddProvisioningKeyToPhones < ActiveRecord::Migration
  def change
    add_column :phones, :provisioning_key, :string

  end
end
