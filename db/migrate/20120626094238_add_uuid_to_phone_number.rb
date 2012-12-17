class AddUuidToPhoneNumber < ActiveRecord::Migration
  def change
    add_column :phone_numbers, :uuid, :string rescue puts "column already added"
    add_column :sip_accounts, :uuid, :string 
    add_column :hunt_groups, :uuid, :string

    add_index :phone_numbers, :uuid rescue puts "index already added"
    add_index :sip_accounts, :uuid
    add_index :hunt_groups, :uuid
  end
end
