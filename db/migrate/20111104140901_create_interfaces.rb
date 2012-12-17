class CreateInterfaces < ActiveRecord::Migration
  def self.up
    create_table :interfaces, :id => false do |t|
      t.string :type,         :limit=>'128'
      t.string :name,         :limit=>'1024'
      t.string :description,  :limit=>'4096'
      t.string :ikey,         :limit=>'1024'
      t.string :filename,     :limit=>'4096'
      t.string :syntax,       :limit=>'4096'
      t.string :hostname,     :limit=>'256'
    end
  end

  def self.down
    drop_table :interfaces
  end
end
