class AddLanguageToSipAccount < ActiveRecord::Migration
  def change
    add_column :sip_accounts, :language_code, :string
  end
end
