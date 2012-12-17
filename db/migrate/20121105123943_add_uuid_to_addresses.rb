class AddUuidToAddresses < ActiveRecord::Migration
  def change
    add_column :addresses, :uuid, :string

  end
end
