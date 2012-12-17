class AddFromFieldToTenant < ActiveRecord::Migration
  def change
    add_column :tenants, :from_field_voicemail_email, :string

    add_column :tenants, :from_field_pin_change_email, :string

  end
end
