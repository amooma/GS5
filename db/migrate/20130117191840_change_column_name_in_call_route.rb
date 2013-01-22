class ChangeColumnNameInCallRoute < ActiveRecord::Migration
  def up
  	if column_exists?(:call_routes, :table)
      rename_column :call_routes, :table, :routing_table
    end
  end
end
