class AddHotdeskableToSipAccount < ActiveRecord::Migration
  def change
    add_column :sip_accounts, :hotdeskable, :boolean

  end
end
