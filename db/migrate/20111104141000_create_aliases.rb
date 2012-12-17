class CreateAliases < ActiveRecord::Migration
  def self.up
    create_table :aliases, :id => false do |t|
      t.integer :sticky
      t.string  :alias,    :limit=>'128'
      t.string  :command,  :limit=>'4096'
      t.string  :hostname, :limit=>'256'
    end
    add_index :aliases, [ :alias ], :unique => false, :name => 'alias1'
  end

  def self.down
    drop_table :aliases
  end
end
