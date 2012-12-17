class CreateVoicemailMsgs < ActiveRecord::Migration
  def self.up
    create_table :voicemail_msgs, :id => false do |t|
      t.integer :created_epoch
      t.integer :read_epoch
      t.string  :username,      :limit => '255'
      t.string  :domain,        :limit => '255'
      t.string  :uuid,          :limit => '255'
      t.string  :cid_name,      :limit => '255'
      t.string  :cid_number,    :limit => '255'
      t.string  :in_folder,     :limit => '255'
      t.string  :file_path,     :limit => '255'
      t.integer :message_len
      t.string  :flags,         :limit => '255'
      t.string  :read_flags,    :limit => '255'
      t.string  :forwarded_by,  :limit => '255'
    end
    add_index :voicemail_msgs, [ :created_epoch ], :unique => false, :name => 'voicemail_msgs_idx1'
    add_index :voicemail_msgs, [ :username ],      :unique => false, :name => 'voicemail_msgs_idx2'
    add_index :voicemail_msgs, [ :domain ],        :unique => false, :name => 'voicemail_msgs_idx3'
    add_index :voicemail_msgs, [ :uuid ],          :unique => false, :name => 'voicemail_msgs_idx4'
    add_index :voicemail_msgs, [ :in_folder ],     :unique => false, :name => 'voicemail_msgs_idx5'
    add_index :voicemail_msgs, [ :read_flags ],    :unique => false, :name => 'voicemail_msgs_idx6'
    add_index :voicemail_msgs, [ :forwarded_by ],  :unique => false, :name => 'voicemail_msgs_idx7'
  end

  def self.down
    drop_table :voicemail_msgs
  end
end
