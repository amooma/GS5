class AddUuidToWhitelists < ActiveRecord::Migration
  def change
    add_column :whitelists, :uuid, :string

  end
end
