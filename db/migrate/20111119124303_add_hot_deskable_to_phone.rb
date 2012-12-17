class AddHotDeskableToPhone < ActiveRecord::Migration
  def change
    add_column :phones, :hot_deskable, :boolean
  end
end
