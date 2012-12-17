class RemoveFaxDocumentableFromFaxDocuments < ActiveRecord::Migration
  def up
    remove_column :fax_documents, :fax_documentable_type
    remove_column :fax_documents, :fax_documentable_id
  end

  def down
    add_column :fax_documents, :fax_documentable_id, :integer
    add_column :fax_documents, :fax_documentable_type, :string
  end
end
