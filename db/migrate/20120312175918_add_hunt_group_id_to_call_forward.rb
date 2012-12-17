class AddHuntGroupIdToCallForward < ActiveRecord::Migration
  def change
    add_column :call_forwards, :hunt_group_id, :integer

  end
end
