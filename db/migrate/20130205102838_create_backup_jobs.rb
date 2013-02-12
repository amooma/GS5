class CreateBackupJobs < ActiveRecord::Migration
  def self.up
    create_table :backup_jobs do |t|
      t.datetime :started_at
      t.datetime :finished_at
      t.string :state
      t.string :directory
      t.integer :size_of_the_backup
      t.timestamps
    end
  end

  def self.down
    drop_table :backup_jobs
  end
end
