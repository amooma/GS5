class RemoveStateFromUser < ActiveRecord::Migration
  def up
    remove_column :users, :state
      end

  def down
    add_column :users, :state, :string
  end
end
