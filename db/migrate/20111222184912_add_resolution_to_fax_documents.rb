class AddResolutionToFaxDocuments < ActiveRecord::Migration
  def change
    add_column :fax_documents, :fax_resolution_id, :integer
  end
end
