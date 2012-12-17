class CreateVoicemailPrefs < ActiveRecord::Migration
  def self.up
    create_table :voicemail_prefs, :id => false do |t|
      t.string :username,      :limit => '255'
      t.string :domain,        :limit => '255'
      t.string :name_path,     :limit => '255'
      t.string :greeting_path, :limit => '255'
      t.string :password,      :limit => '255'
    end
    add_index :voicemail_prefs, [ :username ], :unique => false, :name => 'voicemail_prefs_idx1'
    add_index :voicemail_prefs, [ :domain ],   :unique => false, :name => 'voicemail_prefs_idx2'
  end

  def self.down
    drop_table :voicemail_prefs
  end
end
