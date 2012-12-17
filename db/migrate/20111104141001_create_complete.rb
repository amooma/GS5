class CreateComplete < ActiveRecord::Migration
  def self.up
    create_table :complete, :id => false do |t|
      t.integer :sticky
      t.string  :a1,       :limit=>'128'
      t.string  :a2,       :limit=>'128'
      t.string  :a3,       :limit=>'128'
      t.string  :a4,       :limit=>'128'
      t.string  :a5,       :limit=>'128'
      t.string  :a6,       :limit=>'128'
      t.string  :a7,       :limit=>'128'
      t.string  :a8,       :limit=>'128'
      t.string  :a9,       :limit=>'128'
      t.string  :a10,      :limit=>'128'
      t.string  :hostname, :limit=>'256'
    end
    add_index :complete, [ :a1,  :hostname ], :unique => false, :name => 'complete1'
    add_index :complete, [ :a2,  :hostname ], :unique => false, :name => 'complete2'
    add_index :complete, [ :a3,  :hostname ], :unique => false, :name => 'complete3'
    add_index :complete, [ :a4,  :hostname ], :unique => false, :name => 'complete4'
    add_index :complete, [ :a5,  :hostname ], :unique => false, :name => 'complete5'
    add_index :complete, [ :a6,  :hostname ], :unique => false, :name => 'complete6'
    add_index :complete, [ :a7,  :hostname ], :unique => false, :name => 'complete7'
    add_index :complete, [ :a8,  :hostname ], :unique => false, :name => 'complete8'
    add_index :complete, [ :a9,  :hostname ], :unique => false, :name => 'complete9'
    add_index :complete, [ :a10, :hostname ], :unique => false, :name => 'complete10'
    add_index :complete, [ :a1, :a2, :a3, :a4, :a5, :a6, :a7, :a8, :a9, :a10, :hostname ], :unique => false, :name => 'complete11'
  end

  def self.down
    drop_table :complete
  end
end
