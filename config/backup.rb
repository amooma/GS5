# encoding: utf-8

require 'inifile'
SYSTEM_ODBC_CONFIGURATION = IniFile.load('/var/lib/freeswitch/.odbc.ini')

Backup::Model.new(:gs5, 'GS5 backup') do
 
  ##
  # Split [Splitter]
  #
  # Split the backup file in to chunks of 2 GB
  # if the backup file size exceeds 2 GB
  #
  split_into_chunks_of 2048

  ##
  # MySQL [Database]
  #
  database MySQL do |db|
    # To dump all databases, set `db.name = :all` (or leave blank)
    db.name               = SYSTEM_ODBC_CONFIGURATION['gemeinschaft']['DATABASE']
    db.username           = SYSTEM_ODBC_CONFIGURATION['gemeinschaft']['USER']
    db.password           = SYSTEM_ODBC_CONFIGURATION['gemeinschaft']['PASSWORD']
    db.host               = "localhost"
    db.port               = 3306
    db.socket             = "/var/run/mysqld/mysqld.sock"
  end

  ##
  # Faxes
  #
  archive :faxes do |archive|
    archive.add     '/opt/gemeinschaft/public/uploads/fax_document/'
    archive.add     '/opt/gemeinschaft/public/uploads/fax_thumbnail/'
  end

  ##
  # Voicemails
  #
  archive :voicemails do |archive|
    archive.add     '/var/opt/gemeinschaft/freeswitch/voicemail/'
  end

  ##
  # Local (Copy) [Storage]
  #
  store_with Local do |local|
    local.path       = "/var/backups/"
    local.keep       = 5
  end

  ##
  # Gzip [Compressor]
  #
  compress_with Gzip

end

