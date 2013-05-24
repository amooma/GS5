class AddSwitchableToSwitchboardEntry < ActiveRecord::Migration
  def change
    add_column :switchboard_entries, :switchable, :boolean
  end
end
