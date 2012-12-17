class CreateTenantMemberships < ActiveRecord::Migration
  def change
    create_table :tenant_memberships do |t|
      t.integer :tenant_id
      t.integer :user_id
      t.string :state
      t.integer :position

      t.timestamps
    end
  end
end
