class AddSipAccountIdToAccessAuthorization < ActiveRecord::Migration
  def change
    add_column :access_authorizations, :sip_account_id, :integer
    remove_column :callthroughs, :sip_account_id
  end
end
