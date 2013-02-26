class RestoreJob < ActiveRecord::Base
  attr_accessible :state, :backup_file

  mount_uploader :backup_file, BackupFileUploader

  after_create :queue_the_restore_rake_task

  def to_s
    if self.backup_file?
       File.basename(self.backup_file.to_s)
    else
      "RestoreJob ID #{self.id}"
    end
  end

  private
  def queue_the_restore_rake_task
    self.delay.run_the_restore_rake_task
  end

  def run_the_restore_rake_task
    system "cd #{Rails.root} && rake backup:restore"
  end


end
