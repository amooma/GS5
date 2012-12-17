class AddPhoneableToPhone < ActiveRecord::Migration
  def change
    add_column :phones, :phoneable_type, :string
    add_column :phones, :phoneable_id, :integer
  end
end
