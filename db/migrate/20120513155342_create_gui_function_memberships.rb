class CreateGuiFunctionMemberships < ActiveRecord::Migration
  def change
    create_table :gui_function_memberships do |t|
      t.integer :gui_function_id
      t.integer :user_group_id
      t.boolean :activated
      t.string :output

      t.timestamps
    end
  end
end
