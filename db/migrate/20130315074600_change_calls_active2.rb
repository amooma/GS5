class ChangeCallsActive2 < ActiveRecord::Migration
  def self.up
    execute "DROP VIEW IF EXISTS calls_active"
    if ActiveRecord::Base.connection_config[:adapter] != 'sqlite3'
      execute <<-SQL
        CREATE VIEW calls_active AS SELECT
          a.uuid AS uuid,
          a.direction AS direction,
          a.created_epoch AS start_stamp,
          a.cid_name AS caller_id_name,
          a.cid_num AS caller_id_number,
          a.dest AS destination,
          c.id AS sip_account_id,
          c.caller_name AS sip_caller_name,
          a.callee_name AS callee_name,
          a.callee_num AS callee_number,
          a.callstate AS callstate,
          a.read_codec AS read_codec,
          a.read_rate AS read_rate,
          a.read_bit_rate AS read_bit_rate,
          a.write_codec AS write_codec,
          a.write_rate AS write_rate,
          a.write_bit_rate AS write_bit_rate,
          a.secure AS secure,
          b.uuid AS b_uuid,
          b.cid_name AS b_caller_id_name,
          b.cid_num AS b_caller_id_number,
          b.callstate AS b_callstate,
          d.id AS b_sip_account_id,
          d.caller_name AS b_sip_caller_name,
          b.callee_name AS b_callee_name,
          b.callee_num AS b_callee_number,
          b.secure AS b_secure
          FROM channels a 
          LEFT JOIN channels b ON (a.uuid = b.call_uuid AND a.uuid != b.uuid)
          LEFT JOIN sip_accounts c ON a.presence_id LIKE CONCAT(c.auth_name, "@%")
          LEFT JOIN sip_accounts d ON b.presence_id LIKE CONCAT(d.auth_name, "@%")
          WHERE (a.uuid = b.call_uuid AND a.uuid != b.uuid) 
          OR a.call_uuid IS NULL
          OR a.call_uuid = a.uuid
      SQL
    else
      execute <<-SQL
        CREATE VIEW calls_active AS SELECT
          a.uuid AS uuid,
          a.direction AS direction,
          a.created_epoch AS start_stamp,
          a.cid_name AS caller_id_name,
          a.cid_num AS caller_id_number,
          a.dest AS destination,
          c.id AS sip_account_id,
          c.caller_name AS sip_caller_name,
          a.callee_name AS callee_name,
          a.callee_num AS callee_number,
          a.callstate AS callstate,
          a.read_codec AS read_codec,
          a.read_rate AS read_rate,
          a.read_bit_rate AS read_bit_rate,
          a.write_codec AS write_codec,
          a.write_rate AS write_rate,
          a.write_bit_rate AS write_bit_rate,
          a.secure AS secure,
          b.uuid AS b_uuid,
          b.cid_name AS b_caller_id_name,
          b.cid_num AS b_caller_id_number,
          b.callstate AS b_callstate,
          d.id AS b_sip_account_id,
          d.caller_name AS b_sip_caller_name,
          b.callee_name AS b_callee_name,
          b.callee_num AS b_callee_number,
          b.secure AS b_secure
          FROM channels a 
          LEFT JOIN channels b ON (a.uuid = b.call_uuid AND a.uuid != b.uuid)
          LEFT JOIN sip_accounts c ON a.presence_id LIKE (c.auth_name || "@%")
          LEFT JOIN sip_accounts d ON b.presence_id LIKE (d.auth_name || "@%")
          WHERE (a.uuid = b.call_uuid AND a.uuid != b.uuid) 
          OR a.call_uuid IS NULL
          OR a.call_uuid = a.uuid
      SQL
    end
  end

  def self.down
  
  end
end