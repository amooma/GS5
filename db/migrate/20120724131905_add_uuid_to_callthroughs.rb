class AddUuidToCallthroughs < ActiveRecord::Migration
  def change
    add_column :callthroughs, :uuid, :string

  end
end
