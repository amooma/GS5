class AddBridgeStampToCdrs < ActiveRecord::Migration
  def change
    add_column :cdrs, :bridge_stamp, :datetime

  end
end
