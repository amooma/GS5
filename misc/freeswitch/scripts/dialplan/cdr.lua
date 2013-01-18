-- Gemeinschaft 5 module: cdr class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

Cdr = {}

local DEFAULT_MEMBER_TIMEOUT = 20;

-- Create Cdr object
function Cdr.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.database = arg.database;
  return object;
end


function Cdr.save(self, caller, destination)
  require 'common.str'
  local cdr = {}
  cdr.uuid = common.str.to_sql(caller.uuid);
  cdr.bleg_uuid = common.str.to_sql(caller:to_s('bridge_uuid'));
  cdr.dialed_number = common.str.to_sql(caller.called_number);
  cdr.destination_number = common.str.to_sql(destination.number);
  cdr.caller_id_number = common.str.to_sql(caller:to_s('effective_caller_id_number'));
  cdr.caller_id_name = common.str.to_sql(caller:to_s('effective_caller_id_name'));
  cdr.callee_id_number = common.str.to_sql(caller:to_s('effective_callee_id_number'));
  cdr.callee_id_name = common.str.to_sql(caller:to_s('effective_callee_id_name'));
  cdr.start_stamp = 'FROM_UNIXTIME(' .. math.floor(caller:to_i('created_time') / 1000000) .. ')';
  cdr.answer_stamp = 'FROM_UNIXTIME(' .. math.floor(caller:to_i('answered_time') / 1000000) .. ')';
  cdr.end_stamp = 'NOW()';
  cdr.duration = 'UNIX_TIMESTAMP(NOW()) - ' .. math.floor(caller:to_i('created_time') / 1000000);
  cdr.hangup_cause = common.str.to_sql(caller.session:hangupCause());
  cdr.dialstatus = common.str.to_sql(caller:to_s('DIALSTATUS'));
  cdr.forwarding_number = common.str.to_sql(caller.forwarding_number);
  cdr.forwarding_service = common.str.to_sql(caller.forwarding_service);

  if caller.auth_account then
    cdr.forwarding_account_id = common.str.to_sql(caller.auth_account.id);
    cdr.forwarding_account_type = common.str.to_sql(caller.auth_account.class);
  end

  if caller.account then
    cdr.account_id = common.str.to_sql(caller.account.id);
    cdr.account_type = common.str.to_sql(caller.account.class);
  end

  if caller:to_i('answered_time') > 0 then
    cdr.billsec = 'UNIX_TIMESTAMP(NOW()) - ' .. math.floor(caller:to_i('answered_time') / 1000000);
  end

  cdr.bleg_account_id =   common.str.to_sql(tonumber(destination.id));
  cdr.bleg_account_type = common.str.to_sql(destination.type);

  local keys = {}
  local values = {}

  for key, value in pairs(cdr) do
    table.insert(keys, key);
    table.insert(values, value);
  end

  local sql_query = 'INSERT INTO `cdrs` (`' .. table.concat(keys, "`, `") .. '`) VALUES (' .. table.concat(values, ", ") .. ')';
  self.log:info('CDR_SAVE - caller: ', cdr.account_type, '=', cdr.account_id, ', callee: ',cdr.bleg_account_type, '=', cdr.bleg_account_id,', dialstatus: ', cdr.dialstatus);
  return self.database:query(sql_query);
end
