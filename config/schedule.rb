# Daily Backup
#
every 1.day, :at => '4:00 am' do
  rake "backup:daily_backup"
end

# Auto-Reboot of Phones which should be rebootet
#
every 1.day, :at => '2:30 am' do
  command "/opt/GS5/script/logout_phones"
end

# Learn more: http://github.com/javan/whenever
