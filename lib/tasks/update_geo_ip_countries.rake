namespace :geo_ip_update do
  desc "Update Area Codes and Central Office Codes."
  task :country => :environment do
    ARCHIVE_URL = 'http://geolite.maxmind.com/download/geoip/database/GeoIPCountryCSV.zip'
    ARCHIVE_PATH = '/tmp/geo_ip_countries.zip'
    SOURCE_FILE = '/tmp/GeoIPCountryWhois.csv'

    require 'open-uri'
    open(ARCHIVE_PATH, 'wb') do |file|
      puts 'Downloading GEO-IP database...'
      file << open(ARCHIVE_URL).read
    end

    system("cd /tmp/ && unzip #{ARCHIVE_PATH}")
    all_lines_count = 0
    File.open(SOURCE_FILE, 'r') {|file| all_lines_count = file.read.count("\n")}

    if all_lines_count < 100000
      puts  "Too few lines: #{all_lines_count}"
      return 0
    end

    GeoIpCountry.destroy_all

    lines = 0
    File.open(SOURCE_FILE, 'r').each_line do |line|
      lines += 1

      line_array = line.split(',')
      parameters = {
        :from => line_array[0].gsub('"','').strip,
        :to => line_array[1].gsub('"','').strip,
        :n_from => line_array[2].gsub('"','').to_i,
        :n_to => line_array[3].gsub('"','').to_i,
        :country_code => line_array[4].gsub('"','').strip,
        :country_name => line_array[5].gsub('"','').strip
      }

      percent = lines.to_f / all_lines_count.to_f * 100.0
      puts  "#{all_lines_count} / #{lines} / #{percent.to_i}% / Processing #{parameters[:from]}-#{parameters[:to]} / #{parameters[:country_name]} "
      area_code = GeoIpCountry.create(parameters)
    end
  end
end