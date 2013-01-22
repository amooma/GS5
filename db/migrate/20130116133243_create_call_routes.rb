class CreateCallRoutes < ActiveRecord::Migration
  def self.up
    create_table :call_routes do |t|
      t.string :routing_table
      t.string :name
      t.string :endpoint_type
      t.integer :endpoint_id
      t.integer :position
      t.timestamps
    end
  end

  def self.down
    drop_table :call_routes
  end
end
