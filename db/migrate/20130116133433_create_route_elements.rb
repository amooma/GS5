class CreateRouteElements < ActiveRecord::Migration
  def self.up
    create_table :route_elements do |t|
      t.integer :call_route_id
      t.string :var_in
      t.string :var_out
      t.string :pattern
      t.string :replacement
      t.string :action
      t.boolean :mandatory
      t.integer :position
      t.timestamps
    end
  end

  def self.down
    drop_table :route_elements
  end
end
