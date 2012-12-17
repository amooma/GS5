class AddFaxAccountIdToFaxDocuments < ActiveRecord::Migration
  def change
    add_column :fax_documents, :fax_account_id, :integer
  end
end
