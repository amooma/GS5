class CreateConferences < ActiveRecord::Migration
  def self.up
    create_table :conferences do |t|
      t.string :name
      t.datetime :start
      t.datetime :end
      t.text :description
      t.string :pin
      t.text :state
      t.boolean :open_for_anybody
      t.string :conferenceable_type
      t.integer :conferenceable_id
      t.timestamps
    end
  end

  def self.down
    drop_table :conferences
  end
end
