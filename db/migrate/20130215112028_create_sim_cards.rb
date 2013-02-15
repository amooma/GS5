class CreateSimCards < ActiveRecord::Migration
  def self.up
    create_table :sim_cards do |t|
      t.integer :sim_card_provider_id
      t.string :sim_number
      t.boolean :auto_order_card
      t.integer :sip_account_id
      t.string :auth_key
      t.string :state
      t.text :log
      t.timestamps
    end
  end

  def self.down
    drop_table :sim_cards
  end
end
