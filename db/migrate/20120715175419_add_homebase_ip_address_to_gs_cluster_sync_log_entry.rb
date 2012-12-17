class AddHomebaseIpAddressToGsClusterSyncLogEntry < ActiveRecord::Migration
  def change
    add_column :gs_cluster_sync_log_entries, :homebase_ip_address, :string

  end
end
