class RemovePositionFromTenantMembership < ActiveRecord::Migration
  def up
    remove_column :tenant_memberships, :position
  end

  def down
    add_column :tenant_memberships, :position, :integer
  end
end
