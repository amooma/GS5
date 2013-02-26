class RestoreJob < ActiveRecord::Base
  attr_accessible :state, :backup_file

  mount_uploader :backup_file, BackupFileUploader

  def to_s
    if self.backup_file?
       File.basename(self.backup_file.to_s)
    else
      "RestoreJob ID #{self.id}"
    end
  end  
end
