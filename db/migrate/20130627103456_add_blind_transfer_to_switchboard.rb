class AddBlindTransferToSwitchboard < ActiveRecord::Migration
  def up
    add_column :switchboards, :blind_transfer_activated, :boolean
    add_column :switchboards, :attended_transfer_activated, :boolean

    Switchboard.all.each do |switchboard|
      switchboard.blind_transfer_activated = true
      switchboard.attended_transfer_activated = true
      switchboard.save
    end
  end

  def down
    remove_column :switchboards, :blind_transfer_activated
    remove_column :switchboards, :attended_transfer_activated
  end
end
