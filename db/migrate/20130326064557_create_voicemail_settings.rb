class CreateVoicemailSettings < ActiveRecord::Migration
  def self.up
    create_table :voicemail_settings do |t|
      t.integer :voicemail_account_id
      t.string :name 
      t.string :value
      t.string :class_type
      t.string :description
      t.timestamps
    end
  end

  def self.down
    drop_table :voicemail_settings
  end
end
