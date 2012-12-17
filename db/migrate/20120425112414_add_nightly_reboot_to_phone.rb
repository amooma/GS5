class AddNightlyRebootToPhone < ActiveRecord::Migration
  def change
    add_column :phones, :nightly_reboot, :boolean

  end
end
