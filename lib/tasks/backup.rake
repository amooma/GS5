namespace :backup do
  desc "Backup the system"
  task :daily_backup => :environment do
    # This would be the daily backup.
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
      system "cd #{tmp_dir} && sudo /usr/bin/tar xzf #{restore_job.backup_file.path}"
      restore_directory = Dir.glob("/tmp/gs5_restore_directory/*").first
      system "cd #{restore_directory} && sudo /usr/bin/tar xf GS5.tar && rm GS5.tar"

      # Restore faxes
      #
      system "cd / && sudo /usr/bin/tar xzfP #{restore_directory}/GS5/archives/faxes.tar.gz"

      # Restore voicemails
      #
      # system "cd / && sudo /usr/bin/tar xzfP #{restore_directory}/GS5/archives/voicemails.tar.gz"

      # Restore the database
      #
      system_odbc_ini_file = '/var/lib/freeswitch/.odbc.ini'
      system_odbc_configuration = IniFile.load(system_odbc_ini_file)
      database = system_odbc_configuration['gemeinschaft']['DATABASE']
      db_user = system_odbc_configuration['gemeinschaft']['USER']
      db_password = system_odbc_configuration['gemeinschaft']['PASSWORD']

      system "gunzip < #{restore_directory}/GS5/databases/MySQL/gemeinschaft.sql.gz | mysql -u #{db_user} -p#{db_password} #{database}"

      FileUtils.rm_rf tmp_dir

      system "cd /opt/gemeinschaft && rake db:migrate"
    end
  end

end