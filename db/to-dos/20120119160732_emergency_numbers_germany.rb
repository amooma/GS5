# ruby encoding: utf-8

class EmergencyNumbersGermany < ActiveRecord::Migration

  def up
    # add_column :phone_numbers, :uuid, :string
    # add_index :phone_numbers, :uuid

    germany = Country.find_by_name('Germany')

    ################################################################
    # Emergency numbers which shouldn't be used as extensions
    ################################################################
    notruf_nummern = germany.phone_number_ranges.find_or_create_by_name(GsParameter.get('SERVICE_NUMBERS'))
    notruf_nummern.phone_numbers.find_or_create_by_name_and_number('Polizei', '110')
    notruf_nummern.phone_numbers.find_or_create_by_name_and_number('Feuerwehr', '112')
    notruf_nummern.phone_numbers.find_or_create_by_name_and_number('Zentrale Behördenrufnummer', '115')
    notruf_nummern.phone_numbers.find_or_create_by_name_and_number('Krankenwagen', '19222')
    notruf_nummern.phone_numbers.find_or_create_by_name_and_number('Weisser Ring e. V.', '116006')
    notruf_nummern.phone_numbers.find_or_create_by_name_and_number('Nummer gegen Kummer e. V.', '116111')
    notruf_nummern.phone_numbers.find_or_create_by_name_and_number('Zentrale Anlaufstelle zur Sperrung elektronischer Berechtigungen', '116116')
    notruf_nummern.phone_numbers.find_or_create_by_name_and_number('Kassenärztliche Vereinigung: ärztliche Bereitschaftsdienste', '116117')
    notruf_nummern.phone_numbers.find_or_create_by_name_and_number('Katholische Bundesarbeitsgemeinschaft für Ehe-, Familien- und Lebensberatung, Telefonseelsorge', '116123')
  end

  def down
    germany = Country.find_by_name('Germany')
    germany.phone_number_ranges.where(:name => GsParameter.get('SERVICE_NUMBERS')).destroy_all
  end
end
