class CreateCallsActive < ActiveRecord::Migration
  def self.up
    execute %q{CREATE VIEW calls_active AS SELECT
      a.uuid AS uuid,
      a.direction AS direction,
      a.created_epoch AS start_stamp,
      a.cid_name AS caller_id_name,
      a.cid_num AS caller_id_number,
      a.dest AS destination,
      d.id AS sip_account_id,
      d.caller_name AS sip_caller_name,
      a.callee_name as callee_name,
      a.callee_num as callee_number,
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
      e.id AS b_sip_account_id,
      e.caller_name AS b_sip_caller_name
      FROM channels a 
      LEFT JOIN calls c ON a.uuid = c.caller_uuid AND a.hostname = c.hostname 
      LEFT JOIN channels b ON b.uuid = c.callee_uuid AND b.hostname = c.hostname
      LEFT JOIN sip_accounts d ON a.presence_id LIKE CONCAT(d.auth_name, "@%")
      LEFT JOIN sip_accounts e ON b.presence_id LIKE CONCAT(e.auth_name, "@%")
      WHERE a.uuid = c.caller_uuid OR a.uuid NOT IN (select callee_uuid from calls)}
  end

  def self.down
    execute "DROP VIEW calls_active"
  end
end
