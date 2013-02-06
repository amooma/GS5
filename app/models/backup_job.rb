class BackupJob < ActiveRecord::Base
  attr_accessible :started_at, :finished_at, :state, :directory, :size_of_the_backup

  mount_uploader :backup_file, BackupFileUploader

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
    backup_directory = '/var/backups/GS5'
    backup_name_prefix = 'GS5-backup-'
    if self.finished_at.nil? && self.state == 'queued'
      self.state = 'running'
      self.save
      original_directories = Dir.glob("#{backup_directory}/*")
      system "backup perform --trigger GS5 --config_file #{Rails.root.join('config','backup.rb')}"
      tmp_backup_directory = (Dir.glob("#{backup_directory}/*") - original_directories).first
      if tmp_backup_directory.blank?
        self.state = 'failed'
      else
        system "cd #{backup_directory} && tar czf #{backup_name_prefix}#{tmp_backup_directory}.tar.gz #{tmp_backup_directory}"
        require 'fileutils'
        FileUtils.rm_rf tmp_backup_directory
        file = File::Stat.new("#{backup_directory}/#{backup_name_prefix}#{tmp_backup_directory}.tar.gz")

        self.size_of_the_backup = file.size

        self.backup_file = File.open("#{backup_directory}/#{backup_name_prefix}#{tmp_backup_directory}.tar.gz")

        self.finished_at = Time.now
        self.state = 'successful'
      end
      self.save
    end
  end

  def delete_the_backup_directory
    # if !tmp_backup_directory.blank?
    #   require 'fileutils'
    #   FileUtils.rm_rf tmp_backup_directory
    # end
  end
end
