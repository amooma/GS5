class AddDescriptionToSipAccount < ActiveRecord::Migration
  def change
    add_column :sip_accounts, :description, :string

  end
end
