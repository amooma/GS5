class CreateApiRows < ActiveRecord::Migration
  def change
    create_table :api_rows do |t|
      t.string :user_id
      t.string :user_name
      t.string :last_name
      t.string :middle_name
      t.string :first_name
      t.string :office_phone_number
      t.string :internal_extension
      t.string :mobile_phone_number
      t.string :fax_phone_number
      t.string :email
      t.string :pin
      t.datetime :pin_updated_at
      t.string :photo_file_name

      t.timestamps
    end
  end
end
