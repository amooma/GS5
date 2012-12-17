class CreateSipDomains < ActiveRecord::Migration
  def self.up
    create_table :sip_domains do |t|
      t.string :host
      t.string :realm
      t.timestamps
    end
  end

  def self.down
    drop_table :sip_domains
  end
end
