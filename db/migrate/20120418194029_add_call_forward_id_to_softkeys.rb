class AddCallForwardIdToSoftkeys < ActiveRecord::Migration
  def change
    add_column :softkeys, :call_forward_id, :integer

  end
end
