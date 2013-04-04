class AddAmountOfDisplayedPhoneNumbersToSwitchboard < ActiveRecord::Migration
  def up
    add_column :switchboards, :amount_of_displayed_phone_numbers, :integer

    # Set a default for existing entries of 
    # 1 for amount_of_displayed_phone_numbers
    #
    Switchboard.all.each do |switchboard|
      switchboard.amount_of_displayed_phone_numbers = 1
      switchboard.save
    end
  end

  def down
    remove_column :switchboards, :amount_of_displayed_phone_numbers, :integer
  end
end
