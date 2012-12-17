class AddBlegReadTimeToCdrs < ActiveRecord::Migration
  def change
    add_column :cdrs, :bleg_read_time, :datetime

  end
end
