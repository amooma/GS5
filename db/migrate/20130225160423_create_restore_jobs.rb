class CreateRestoreJobs < ActiveRecord::Migration
  def self.up
    create_table :restore_jobs do |t|
      t.string :state
      t.string :backup_file
      t.timestamps
    end
  end

  def self.down
    drop_table :restore_jobs
  end
end
