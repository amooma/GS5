class RemoveResultTextFromFaxDocuments < ActiveRecord::Migration
  def up
    remove_column :fax_documents, :result_text
    add_column :fax_documents, :retry_counter, :integer
    add_column :fax_accounts, :retries, :integer
  end

  def down
    add_column :fax_documents, :result_text, :string
    remove_column :fax_documents, :retry_counter
    remove_column :fax_accounts, :retries
  end
end
