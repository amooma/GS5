class CreateFaxDocuments < ActiveRecord::Migration
  def self.up
    create_table :fax_documents do |t|
      t.string :fax_documentable_type
      t.integer :fax_documentable_id
      t.boolean :inbound
      t.string :state
      t.integer :transmission_time
      t.datetime :sent_at
      t.integer :document_total_pages
      t.integer :document_transferred_pages
      t.boolean :ecm_requested
      t.boolean :ecm_used
      t.string :image_resolution
      t.string :image_size
      t.string :local_station_id
      t.integer :result_code
      t.string :result_text
      t.string :remote_station_id
      t.boolean :success
      t.integer :transfer_rate
      t.string :t38_gateway_format
      t.string :t38_peer
      t.string :document
      t.timestamps
    end
  end

  def self.down
    drop_table :fax_documents
  end
end
