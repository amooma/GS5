class AddMaxMembersToConference < ActiveRecord::Migration
  def change
    add_column :conferences, :max_members, :integer
  end
end
