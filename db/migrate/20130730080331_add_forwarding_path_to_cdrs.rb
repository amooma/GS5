class AddForwardingPathToCdrs < ActiveRecord::Migration
  def change
    add_column :cdrs, :forwarding_path, :string
  end
end
