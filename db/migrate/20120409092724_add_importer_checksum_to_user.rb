class AddImporterChecksumToUser < ActiveRecord::Migration
  def change
    add_column :users, :importer_checksum, :string

  end
end
