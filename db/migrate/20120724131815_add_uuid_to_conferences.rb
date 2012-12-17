class AddUuidToConferences < ActiveRecord::Migration
  def change
    add_column :conferences, :uuid, :string

  end
end
