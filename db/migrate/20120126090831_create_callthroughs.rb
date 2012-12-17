class CreateCallthroughs < ActiveRecord::Migration
  def self.up
    create_table :callthroughs do |t|
      t.integer :tenant_id
      t.string :name
      t.integer :sip_account_id
      t.string :clip_no_screening
      t.timestamps
    end
  end

  def self.down
    drop_table :callthroughs
  end
end
