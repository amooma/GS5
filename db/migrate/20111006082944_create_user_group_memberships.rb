class CreateUserGroupMemberships < ActiveRecord::Migration
  def change
    create_table :user_group_memberships do |t|
      t.integer :user_group_id
      t.integer :user_id
      t.string :state

      t.timestamps
    end
  end
end
