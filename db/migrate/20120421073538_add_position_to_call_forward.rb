class AddPositionToCallForward < ActiveRecord::Migration
  def change
    add_column :call_forwards, :position, :integer

  end
end
