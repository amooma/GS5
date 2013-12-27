namespace :backup do
  desc "Backup the system"
  task :daily_backup => :environment do
    # This would be the daily backup.
  end

  desc "Do a backup."
  task :queue_a_new_backup => :environment do
    backup_job = BackupJob.create
    puts "BackupJob ID: #{backup_job.id}"
  end

  desc "Do a backup. Now!"
  task :force_now => :environment do
    backup_job = BackupJob.create(:state => 'force now')
    puts "BackupJob ID: #{backup_job.id}"
  end

  desc "Restore the system"
  task :restore => :environment do
    # This task takes the first RestoreJob to restore the system.
    #
    if RestoreJob.where(:state => 'new').any?
      restore_job = RestoreJob.where(:state => 'new').order(:created_at).last
      tmp_dir = "/tmp/gs5_restore_directory"
      FileUtils.rm_rf tmp_dir
      FileUtils.mkdir_p tmp_dir
      system "cd #{tmp_dir} && nice -n 19 ionice -c2 -n7 sudo /bin/tar xzf #{restore_job.backup_file.path}"
      restore_directory = Dir.glob("/tmp/gs5_restore_directory/*").first
      system "cd #{restore_directory} && nice -n 19 ionice -c2 -n7 sudo /bin/tar xf GS5.tar && rm GS5.tar"

      # Restore faxes
      #
      if File.exists?("#{restore_directory}/GS5/archives/faxes.tar.gz")
        system "cd / && nice -n 19 ionice -c2 -n7 sudo /bin/tar xzfP #{restore_directory}/GS5/archives/faxes.tar.gz"
      end

      # Restore voicemails
      #
      if File.exists?("#{restore_directory}/GS5/archives/voicemails.tar.gz")
        system "cd / && nice -n 19 ionice -c2 -n7 sudo /bin/tar xzfP #{restore_directory}/GS5/archives/voicemails.tar.gz"
      end

      # Restore recordings
      #
      if File.exists?("#{restore_directory}/GS5/archives/recordings.tar.gz")
        system "cd / && nice -n 19 ionice -c2 -n7 sudo /bin/tar xzfP #{restore_directory}/GS5/archives/recordings.tar.gz"
      end

      # Restore avatars
      #
      if File.exists?("#{restore_directory}/GS5/archives/avatars.tar.gz")
        system "cd / && nice -n 19 ionice -c2 -n7 sudo /bin/tar xzfP #{restore_directory}/GS5/archives/avatars.tar.gz"
      end

      # Delete the archive tar.gz to get more air to breathe
      #
      FileUtils.mkdir_p "#{restore_directory}/GS5/archives"

      # Restore the database
      #
      system_odbc_ini_file = '/var/lib/freeswitch/.odbc.ini'
      system_odbc_configuration = IniFile.load(system_odbc_ini_file)
      database = system_odbc_configuration['gemeinschaft']['DATABASE']
      db_user = system_odbc_configuration['gemeinschaft']['USER']
      db_password = system_odbc_configuration['gemeinschaft']['PASSWORD']

      system "nice -n 19 ionice -c2 -n7 gunzip < #{restore_directory}/GS5/databases/MySQL/gemeinschaft.sql.gz | nice -n 19 ionice -c2 -n7 mysql -u #{db_user} -p#{db_password} #{database}"

      FileUtils.rm_rf tmp_dir

      system "cd /opt/gemeinschaft && nice -n 19 ionice -c2 -n7 rake db:migrate"

      # Rebuild the thumbnails
      #
      FaxDocument.all.each do |fax_document|
        fax_document.render_thumbnails
      end

      # Delete the restore_job. No need to waste that space.
      #
      restore_job.destroy
    end
  end

  desc "Cleanup backups."
  task :cleanup, [:daystokeep] => :environment do |t,a|
    # this task will purge all backups started before :daystokeep (default 90) days from disk and database to save disk space
    # usage: rake backup:cleanup[14]
    a.with_defaults(:daystokeep => 90)
    cleanuptime = Time.now - a.daystokeep.to_i.day
    puts "Deleting backups to #{cleanuptime.to_s} ..."
    BackupJob.where("started_at < ?",cleanuptime).find_each { |entry| entry.destroy }
    puts "Done."
  end
end
