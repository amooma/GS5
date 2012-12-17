class AddFaxToFaxes < ActiveRecord::Migration
  def change
    remove_column :faxes, :pdf
    remove_column :fax_pages, :page
    add_column :faxes, :fax, :string
    add_column :fax_pages, :fax_page, :string
  end
end
