class AddUuidToSoftkeys < ActiveRecord::Migration
  def change
    add_column :softkeys, :uuid, :string

  end
end
