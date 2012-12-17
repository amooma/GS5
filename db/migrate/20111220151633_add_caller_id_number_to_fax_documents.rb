class AddCallerIdNumberToFaxDocuments < ActiveRecord::Migration
  def change
    add_column :fax_documents, :caller_id_number, :string
    add_column :fax_documents, :caller_id_name, :string
    remove_column :fax_documents, :t38_gateway_format
    remove_column :fax_documents, :t38_peer
  end
end
