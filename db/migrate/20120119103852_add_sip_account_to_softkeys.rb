class AddSipAccountToSoftkeys < ActiveRecord::Migration
  def change
    add_column :softkeys, :sip_account_id, :integer
    remove_column :softkeys, :phone_id
  end
end
