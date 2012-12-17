class RemovePositionFromTenant < ActiveRecord::Migration
  def up
    remove_column :tenants, :position
  end

  def down
    add_column :tenants, :position, :integer
  end
end
