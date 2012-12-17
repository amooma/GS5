class AddUuidToFaxAccounts < ActiveRecord::Migration
  def change
    add_column :fax_accounts, :uuid, :string

  end
end
