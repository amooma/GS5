class BackupJob < ActiveRecord::Base
  attr_accessible :started_at, :finished_at, :state, :directory, :size_of_the_backup

  before_create :set_state_to_queued
  after_create :initiate_backup
  after_destroy :delete_the_backup_directory

  private
  def set_state_to_queued
    self.state = 'queued'
    self.started_at = Time.now
  end

  def initiate_backup
    self.delay.make_a_backup
  end

  def make_a_backup
    if self.finished_at.nil? && self.state == 'queued'
      self.state = 'running'
      self.save
      original_directories = Dir.glob('/var/backups/GS5/*')
      system "backup perform --trigger GS5 --config_file #{Rails.root.join('config','backup.rb')}"
      self.directory = (Dir.glob('/var/backups/GS5/*') - original_directories).first
      if self.directory.blank?
        self.state = 'failed'
      else
        file = File::Stat.new(self.directory)
        self.size_of_the_backup = file.size
        self.finished_at = Time.now
        self.state = 'successful'
      end
      self.save
    end
  end

  def delete_the_backup_directory
    if !self.directory.blank?
      require 'fileutils'
      FileUtils.rm_rf self.directory
    end
  end
end
