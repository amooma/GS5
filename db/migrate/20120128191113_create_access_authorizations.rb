class CreateAccessAuthorizations < ActiveRecord::Migration
  def self.up
    create_table :access_authorizations do |t|
      t.string :access_authorizationable_type
      t.integer :access_authorizationable_id
      t.string :name
      t.string :login
      t.string :pin
      t.integer :position
      t.timestamps
    end
  end

  def self.down
    drop_table :access_authorizations
  end
end
