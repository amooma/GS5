class CreateFaxAccounts < ActiveRecord::Migration
  def self.up
    create_table :fax_accounts do |t|
      t.string :fax_accountable_type
      t.integer :fax_accountable_id
      t.string :name
      t.string :email
      t.boolean :delete_after_email
      t.timestamps
    end
  end

  def self.down
    drop_table :fax_accounts
  end
end
