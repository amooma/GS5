class AddCentralOfficeCodeToAreaCode < ActiveRecord::Migration
  def change
    add_column :area_codes, :central_office_code, :string
  end
end
