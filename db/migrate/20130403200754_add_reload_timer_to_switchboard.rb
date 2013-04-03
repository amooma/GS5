class AddReloadTimerToSwitchboard < ActiveRecord::Migration
  def change
    add_column :switchboards, :reload_interval, :integer
    add_column :switchboards, :show_avatars, :boolean
    add_column :switchboards, :entry_width, :integer
  end
end
