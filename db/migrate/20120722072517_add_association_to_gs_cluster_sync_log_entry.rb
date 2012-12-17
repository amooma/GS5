class AddAssociationToGsClusterSyncLogEntry < ActiveRecord::Migration
  def change
    add_column :gs_cluster_sync_log_entries, :association_method, :string

    add_column :gs_cluster_sync_log_entries, :association_uuid, :string

  end
end
