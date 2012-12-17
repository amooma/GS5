class AddHopsToCallForward < ActiveRecord::Migration
  def change
    add_column :call_forwards, :hops, :integer
  end
end
