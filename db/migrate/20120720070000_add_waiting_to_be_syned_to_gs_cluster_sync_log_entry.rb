class AddWaitingToBeSynedToGsClusterSyncLogEntry < ActiveRecord::Migration
  def change
    add_column :gs_cluster_sync_log_entries, :waiting_to_be_synced, :boolean

  end
end
