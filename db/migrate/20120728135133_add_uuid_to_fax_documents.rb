class AddUuidToFaxDocuments < ActiveRecord::Migration
  def change
    add_column :fax_documents, :uuid, :string

  end
end
