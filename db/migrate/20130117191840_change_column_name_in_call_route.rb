class ChangeColumnNameInCallRoute < ActiveRecord::Migration
  def up
    rename_column :call_routes, :table, :routing_table
  end

  def down
    rename_column :call_routes, :routing_table, :table
  end
end
