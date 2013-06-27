class AddSearchActivatedToSwitchboard < ActiveRecord::Migration
  def change
    add_column :switchboards, :search_activated, :boolean
  end
end
