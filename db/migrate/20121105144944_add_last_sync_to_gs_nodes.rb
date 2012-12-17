class AddLastSyncToGsNodes < ActiveRecord::Migration
  def change
    add_column :gs_nodes, :last_sync, :datetime

  end
end
