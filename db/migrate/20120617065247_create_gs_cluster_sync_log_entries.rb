class CreateGsClusterSyncLogEntries < ActiveRecord::Migration
  def self.up
    create_table :gs_cluster_sync_log_entries do |t|
      t.integer :gs_node_id
      t.string :class_name
      t.string :action
      t.text :content
      t.string :status
      t.string :history
      t.timestamps
    end
  end

  def self.down
    drop_table :gs_cluster_sync_log_entries
  end
end
