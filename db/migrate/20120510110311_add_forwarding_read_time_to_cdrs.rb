class AddForwardingReadTimeToCdrs < ActiveRecord::Migration
  def change
    add_column :cdrs, :forwarding_read_time, :datetime

  end
end
