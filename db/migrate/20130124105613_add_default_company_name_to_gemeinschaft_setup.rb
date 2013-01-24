class AddDefaultCompanyNameToGemeinschaftSetup < ActiveRecord::Migration
  def change
    add_column :gemeinschaft_setups, :default_company_name, :string
    add_column :gemeinschaft_setups, :default_system_email, :string
  end
end
