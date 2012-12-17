class CreateFaxThumbnails < ActiveRecord::Migration
  def change
    create_table :fax_thumbnails do |t|
      t.integer :fax_document_id
      t.integer :position
      t.string :thumbnail

      t.timestamps
    end
  end
end
