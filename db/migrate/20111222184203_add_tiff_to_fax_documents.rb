class AddTiffToFaxDocuments < ActiveRecord::Migration
  def change
    add_column :fax_documents, :tiff, :string
  end
end
