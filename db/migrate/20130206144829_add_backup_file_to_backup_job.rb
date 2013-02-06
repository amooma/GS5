class AddBackupFileToBackupJob < ActiveRecord::Migration
  def change
    add_column :backup_jobs, :backup_file, :string
  end
end
