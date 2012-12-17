class AddStateToPhone < ActiveRecord::Migration
  def change
    add_column :phones, :state, :string
  end
end
