class AddDepthToCallForward < ActiveRecord::Migration
  def change
    rename_column :call_forwards, :hops, :depth
  end
end
