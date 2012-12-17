class AddInformationToFax < ActiveRecord::Migration
  def change
    remove_column :faxes, :number_of_pages
    add_column :faxes, :document_total_pages, :integer
    add_column :faxes, :document_transferred_pages, :integer
    add_column :faxes, :ecm_requested, :boolean
    add_column :faxes, :ecm_used, :boolean
    add_column :faxes, :image_resolution, :string
    add_column :faxes, :image_size, :string
    add_column :faxes, :local_station_id, :string
    add_column :faxes, :result_code, :integer
    add_column :faxes, :result_text, :string
    add_column :faxes, :remote_station_id, :string
    add_column :faxes, :success, :boolean
    add_column :faxes, :transfer_rate, :integer
    add_column :faxes, :t38_gateway_format, :string
    add_column :faxes, :t38_peer, :string
  end
end
