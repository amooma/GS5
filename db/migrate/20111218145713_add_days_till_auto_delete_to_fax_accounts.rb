class AddDaysTillAutoDeleteToFaxAccounts < ActiveRecord::Migration
  def change
    add_column :fax_accounts, :days_till_auto_delete, :integer
    remove_column :fax_accounts, :delete_after_email
  end
end
