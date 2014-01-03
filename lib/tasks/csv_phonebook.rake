namespace :csvphonebook do
  require 'csv'

  # CSV format (headers are inspired by LDAP attributes):
  #
  # givenName,sn,company,telephoneNumber,mobile,department,streetAddress,postalCode,l,title
  # Max,Mustermann,Musterfirma,+123456789,+91123456789,Abteilung XY,Musterstraße 1 a,12345,Musterstadt,Musterchief

  desc "Delete phonebook entries from a CSV file."
  task :delete, [:csvfile, :phonebookname] => :environment do |t,a|

    csv_data    = CSV.read(a.csvfile, encoding: 'UTF-8')
    phonebookid = PhoneBook.find(:first, :conditions => { :name => a.phonebookname}).id
    headers     = csv_data.shift.map {|i| i.to_s }
    string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
    entries     = string_data.map {|row| Hash[*headers.zip(row).flatten] }

    entries.each do |entry|
      if !(entry['givenName'].blank? || entry['sn'].blank? || entry['company'].blank?)
        pbe = PhoneBookEntry.find(:first,:conditions => {
          :phone_book_id => phonebookid,
          :first_name => entry['givenName'],
          :last_name => entry['sn'],
          :organization => entry['company']
        })
        if !pbe.nil?
          pbe.delete
        end
      end
    end
  end

  desc "Add new phonebook entries from CSV file."
  task :add, [:csvfile, :phonebookname] => :environment do |t,a|

    csv_data    = CSV.read(a.csvfile, encoding: 'UTF-8')
    phonebookid = PhoneBook.find(:first, :conditions => { :name => a.phonebookname}).id
    headers     = csv_data.shift.map {|i| i.to_s }
    string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
    entries     = string_data.map {|row| Hash[*headers.zip(row).flatten] }

    entries.each do |entry|
      if !(entry['givenName'].blank? || entry['sn'].blank? || entry['company'].blank?)
        pbe               = PhoneBookEntry.new
        pbe.first_name    = entry['givenName']
        pbe.last_name     = entry['sn']
        pbe.organization  = entry['company']
        pbe.is_male       = 1
        pbe.department    = entry['department']
        pbe.job_title     = entry['title']
        pbe.phone_book_id = phonebookid
        pbe.save

        if !(entry['telephoneNumber'].blank?)
          number                       = PhoneNumber.new
          number.name                  = 'Office'
          number.number                = entry['telephoneNumber']
          number.phone_numberable_type = 'PhoneBookEntry'
          number.phone_numberable_id   = pbe.id
          number.save
        end
        if !(entry['mobile'].blank?)
          number                       = PhoneNumber.new
          number.name                  = 'Mobile'
          number.number                = entry['mobile']
          number.phone_numberable_type = 'PhoneBookEntry'
          number.phone_numberable_id   = pbe.id
          number.save
        end
        if !(entry['streetAddress'].blank? && entry['postalCode'].blank? && entry['l'].blank?)
          addr                     = Address.new
          addr.street              = entry['streetAddress']
          addr.zip_code            = entry['postalCode']
          addr.city                = entry['l']
          addr.phone_book_entry_id = pbe.id
          addr.save
        end
      end
    end
  end
end
