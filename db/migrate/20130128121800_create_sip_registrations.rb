class CreateSipRegistrations < ActiveRecord::Migration
  def self.up
    if !(ActiveRecord::Base.connection.table_exists? 'sip_registrations')
      create_table :sip_registrations, :id => false do |t|
        t.string  :call_id,          :limit => '255'
        t.string  :sip_user,         :limit => '255'
        t.string  :sip_host,         :limit => '255'
        t.string  :presence_hosts,   :limit => '255'
        t.string  :contact,          :limit => '1024'
        t.string  :status,           :limit => '255'
        t.string  :rpid,             :limit => '255'
        t.integer :expires
        t.string  :user_agent,       :limit => '255'
        t.string  :server_user,      :limit => '255'
        t.string  :server_host,      :limit => '255'
        t.string  :profile_name,     :limit => '255'
        t.string  :hostname,         :limit => '255'
        t.string  :network_ip,       :limit => '255'
        t.string  :network_port,     :limit => '6'
        t.string  :sip_username,     :limit => '255'
        t.string  :sip_realm,        :limit => '255'
        t.string  :mwi_user,         :limit => '255'
        t.string  :mwi_host,         :limit => '255'
        t.string  :orig_server_host, :limit => '255'
        t.string  :orig_hostname,    :limit => '255'
        t.string  :sub_host,         :limit => '255'
      end

      add_index :sip_registrations, [ :call_id ], :name => 'sr_call_id'
      add_index :sip_registrations, [ :sip_user ], :name => 'sr_sip_user'
      add_index :sip_registrations, [ :sip_host ], :name => 'sr_sip_host'
      add_index :sip_registrations, [ :sub_host ], :name => 'sr_sub_host'
      add_index :sip_registrations, [ :mwi_user ], :name => 'sr_mwi_user'
      add_index :sip_registrations, [ :mwi_host ], :name => 'sr_mwi_host'
      add_index :sip_registrations, [ :profile_name ], :name => 'sr_profile_name'
      add_index :sip_registrations, [ :presence_hosts ], :name => 'sr_presence_hosts'
      add_index :sip_registrations, [ :contact ], :name => 'sr_contact'
      add_index :sip_registrations, [ :expires ], :name => 'sr_expires'
      add_index :sip_registrations, [ :hostname ], :name => 'sr_hostname'
      add_index :sip_registrations, [ :status ], :name => 'sr_status'
      add_index :sip_registrations, [ :network_ip ], :name => 'sr_network_ip'
      add_index :sip_registrations, [ :network_port ], :name => 'sr_network_port'
      add_index :sip_registrations, [ :sip_username ], :name => 'sr_sip_username'
      add_index :sip_registrations, [ :sip_realm ], :name => 'sr_sip_realm'
      add_index :sip_registrations, [ :orig_server_host ], :name => 'sr_orig_server_host'
      add_index :sip_registrations, [ :orig_hostname ], :name => 'sr_orig_hostname'
    end
  end

  def self.down
    drop_table :sip_registrations
  end
end
