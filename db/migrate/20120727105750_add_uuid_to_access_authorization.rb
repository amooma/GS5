class AddUuidToAccessAuthorization < ActiveRecord::Migration
  def change
    add_column :access_authorizations, :uuid, :string
    add_index :access_authorizations, :uuid

  end
end
