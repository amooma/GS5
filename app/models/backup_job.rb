class BackupJob < ActiveRecord::Base
  attr_accessible :started_at, :finished_at, :state, :directory, :size_of_the_backup

  after_create :start_the_backup

  private
  def start_the_backup
  	if self.finished_at.nil?
      system "backup perform --trigger gs5 --config_file #{Rails.root.join('config','backup.rb')}"
      self.finished_at = Time.now
      self.save
    end
  end
end
