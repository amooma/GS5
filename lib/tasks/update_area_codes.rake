namespace :area_codes_update do
  desc "Update Area Codes and Central Office Codes."
  task :nanp => :environment do
    ARCHIVE_URL = 'http://www.nanpa.com/nanp1/allutlzd.zip'
    ARCHIVE_PATH = '/tmp/nanp_area_codes.zip'
    SOURCE_FILE = '/tmp/allutlzd.txt'

    country = Country.where(:name => "United States of America" ).first

    require 'open-uri'
    open(ARCHIVE_PATH, 'wb') do |file|
      puts 'Downloading area codes list...'
      file << open(ARCHIVE_URL).read
    end

    system("cd /tmp/ && unzip #{ARCHIVE_PATH}")
    all_lines_count = 0
    File.open(SOURCE_FILE, 'r') {|file| all_lines_count = file.read.count("\n")}

    lines = 0
    File.open(SOURCE_FILE, 'r').each_line do |line|
      lines += 1

      if lines == 1
        next
      end

      line_array = line.split("\t")

      state = line_array[0].strip
      npa, ncc = line_array[1].split("-")
      rate_center = line_array[4].strip.titleize

      if rate_center.blank? || line_array[6].strip != 'AS' || rate_center == 'Xxxxxxxxxx'
        next
      end

      name = "#{rate_center}, #{state}"
      percent = lines.to_f / all_lines_count.to_f * 100.0
      puts  "#{all_lines_count} / #{lines} / #{percent.to_i}% / Processing #{name} / +1-#{npa}-#{ncc} "

      area_code = AreaCode.where(:country_id => country.id, :area_code => npa, :central_office_code => ncc).first
      if !area_code
        area_code = AreaCode.create(:country_id => country.id, :area_code => npa, :central_office_code => ncc, :name => name)
      else
        if area_code.name != name
          area_code.update_attributes({ :name => name })
        end
      end
    end
  end
end