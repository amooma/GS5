class AddReverseLookupToSwitchboard < ActiveRecord::Migration
  def change
    add_column :switchboards, :reverse_lookup_activated, :boolean
  end
end
