class RemoveSizeOfTheBackupFromBackupJob < ActiveRecord::Migration
  def up
    remove_column :backup_jobs, :size_of_the_backup
  end

  def down
    add_column :backup_jobs, :size_of_the_backup, :string
  end
end
