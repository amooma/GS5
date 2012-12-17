# encoding: UTF-8

class AddMoreGermanAreaCodes < ActiveRecord::Migration
  def up
    # http://www.bundesnetzagentur.de/cln_1912/DE/Sachgebiete/Telekommunikation/RegulierungTelekommunikation/Nummernverwaltung/Nummernverwaltung_node.html

    germany = Country.find_by_name('Germany')
    german_service_number_range = germany.phone_number_ranges.find_by_name('service_numbers')

    # Harmonisierte Dienste von sozialem Wert
    #
    (0..9).each do |x|
      (0..9).each do |y|
        (0..9).each do |z|
          german_service_number_range.phone_numbers.create( 
                            :name => "Harmonisierte Dienste von sozialem Wert", 
                            :number => "116#{x}#{y}#{z}" 
                                                          )
        end
      end
    end 

    # Auskunftsdienste
    #
    (0..9).each do |x|
      (0..9).each do |y|
          german_service_number_range.phone_numbers.create( 
                            :name => "Auskunftsdienste", 
                            :number => "118#{x}#{y}" 
                                                          )
      end
    end

    # Online-Dienste
    #
    (0..9).each do |x|
      (0..9).each do |y|
        (0..9).each do |z|
          AreaCode.create( 
                           :country_id => germany.id, 
                           :name => 'Online-Dienste', 
                           :area_code => "19#{x}#{y}#{z}"
                         )
        end
      end
    end

    AreaCode.create(:country_id => germany.id, :name => 'Neuartige Dienste', :area_code => '12')
    AreaCode.create(:country_id => germany.id, :name => 'Massenverkehrs-Dienste', :area_code => '137')
    AreaCode.create(:country_id => germany.id, :name => 'Nutzergruppen', :area_code => '18')
    AreaCode.create(:country_id => germany.id, :name => 'Internationale Virtuelle Private Netze', :area_code => '181')
    AreaCode.create(:country_id => germany.id, :name => 'Nationale Teilnehmernummern', :area_code => '32')
    AreaCode.create(:country_id => germany.id, :name => 'Anwählprogramme (Dialer)', :area_code => '9009')
  end

  def down
  end
end
