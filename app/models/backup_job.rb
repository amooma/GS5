class BackupJob < ActiveRecord::Base
  attr_accessible :started_at, :finished_at, :state, :directory, :size_of_the_backup

  after_create :initiate_backup

  private
  def initiate_backup
    self.delay.make_a_backup
  end

  def make_a_backup
    if self.finished_at.nil?
      original_directories = Dir.glob('/var/backups/GS5/*')
      system "backup perform --trigger GS5 --config_file #{Rails.root.join('config','backup.rb')}"
      self.directory = (Dir.glob('/var/backups/GS5/*') - original_directories).first
      if self.directory.blank?
        self.state = 'unsuccessful'
      else
        self.size_of_the_backup = (`du -hs #{new_directory}`).split(/\t/).first
        self.finished_at = Time.now
        self.state = 'successful'
      end
      self.save
    end
  end
end
