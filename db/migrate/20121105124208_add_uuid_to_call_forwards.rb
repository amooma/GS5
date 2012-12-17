class AddUuidToCallForwards < ActiveRecord::Migration
  def change
    add_column :call_forwards, :uuid, :string

  end
end
