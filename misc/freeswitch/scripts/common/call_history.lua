-- Gemeinschaft 5 module: call_history class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)


function camelize_type(account_type)
  ACCOUNT_TYPES = {
    sipaccount = 'SipAccount',
    conference = 'Conference', 
    faxaccount = 'FaxAccount', 
    callthrough = 'Callthrough', 
    huntgroup = 'HuntGroup', 
    automaticcalldistributor = 'AutomaticCallDistributor',
  }

  return ACCOUNT_TYPES[account_type] or account_type;
end


CallHistory = {}

-- Create CallHistory object
function CallHistory.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.class = 'callhistory';
  self.log = arg.log;
  self.database = arg.database;
  return object;
end


function CallHistory.insert_entry(self, call_history)
  local keys = {}
  local values = {}

  call_history.created_at = 'NOW()';
  call_history.updated_at = 'NOW()';

  for key, value in pairs(call_history) do
    table.insert(keys, key);
    table.insert(values, value);
  end

  local sql_query = 'INSERT INTO `call_histories` (`' .. table.concat(keys, "`, `") .. '`) VALUES (' .. table.concat(values, ", ") .. ')';
  local result = self.database:query(sql_query);
  if not result then
    self.log:error('[', call_history.caller_channel_uuid, '] CALL_HISTORY_SAVE - SQL: ', sql_query);
  end
  return result;
end


function CallHistory.insert_event(self, uuid, account_type, account_id, entry_type, event)
  require 'common.str'
  local call_history = {}

  call_history.entry_type = common.str.to_sql(entry_type);
  call_history.call_historyable_type = common.str.to_sql(camelize_type(account_type));
  call_history.call_historyable_id = common.str.to_sql(account_id);
  call_history.caller_channel_uuid = common.str.to_sql(uuid);
  call_history.duration = common.str.to_sql(event:getHeader('variable_billsec'));
  call_history.caller_id_number = common.str.to_sql(event:getHeader('variable_effective_caller_id_number'));
  call_history.caller_id_name = common.str.to_sql(event:getHeader('variable_effective_caller_id_name'));
  call_history.callee_id_number = common.str.to_sql(event:getHeader('variable_effective_callee_id_number'));
  call_history.callee_id_name = common.str.to_sql(event:getHeader('variable_effective_callee_id_name'));
  call_history.result = common.str.to_sql(event:getHeader('variable_hangup_cause'));
  call_history.start_stamp = 'FROM_UNIXTIME(' .. math.floor(common.str.to_i(event:getHeader('Caller-Channel-Created-Time')) / 1000000) .. ')';
  call_history.auth_account_type = common.str.to_sql(camelize_type(event:getHeader('variable_gs_auth_account_type')));
  call_history.auth_account_id = common.str.to_sql(event:getHeader('variable_gs_auth_account_id'));
  call_history.callee_account_type = common.str.to_sql(camelize_type(event:getHeader('variable_gs_destination_type')));
  call_history.callee_account_id = common.str.to_sql(event:getHeader('variable_gs_destination_id'));
  call_history.destination_number = common.str.to_sql(event:getHeader('variable_gs_destination_number'));
  call_history.forwarding_service = common.str.to_sql(event:getHeader('variable_gs_forwarding_service'));

  if not common.str.to_b(event:getHeader('variable_gs_clir')) then
    call_history.caller_account_type = common.str.to_sql(camelize_type(event:getHeader('variable_gs_caller_account_type') or event:getHeader('variable_gs_account_type')));
    call_history.caller_account_id = common.str.to_sql(event:getHeader('variable_gs_caller_account_id') or event:getHeader('variable_gs_account_id'));
  end

  if common.str.to_s(event:getHeader('variable_gs_call_service')) == 'pickup' then
    call_history.forwarding_service = common.str.to_sql('pickup');
  end

  self.log:info('[', uuid,'] CALL_HISTORY_SAVE ', entry_type,' - account: ', account_type, '=', account_id, 
    ', caller: ', call_history.caller_id_number, ' ', call_history.caller_id_name,
    ', callee: ', call_history.callee_id_number, ' ', call_history.callee_id_name,
    ', result: ', call_history.result
  );

  return self:insert_entry(call_history);
end


function CallHistory.insert_forwarded(self, uuid, account_type, account_id, caller, destination, result)
  require 'common.str'

  local call_history = {}

  call_history.entry_type = common.str.to_sql('forwarded');
  call_history.call_historyable_type = common.str.to_sql(camelize_type(account_type));
  call_history.call_historyable_id = common.str.to_sql(account_id);
  call_history.caller_channel_uuid = common.str.to_sql(uuid);

  call_history.duration = common.str.to_sql(caller:to_i('billsec'));
  call_history.caller_id_number = common.str.to_sql(caller.caller_id_number);
  call_history.caller_id_name = common.str.to_sql(caller.caller_id_name);
  call_history.callee_id_number = common.str.to_sql(caller.callee_id_number);
  call_history.callee_id_name = common.str.to_sql(caller.callee_id_name);
  call_history.result = common.str.to_sql(result.cause or 'UNSPECIFIED');
  call_history.start_stamp = 'FROM_UNIXTIME(' .. math.floor(caller:to_i('created_time') / 1000000) .. ')';

  if caller.account and not caller.clir then
    call_history.caller_account_type = common.str.to_sql(camelize_type(caller.account.class));
    call_history.caller_account_id = common.str.to_sql(caller.account.id);
  end

  if caller.auth_account then
    call_history.auth_account_type = common.str.to_sql(camelize_type(caller.auth_account.class));
    call_history.auth_account_id = common.str.to_sql(caller.auth_account.id);
  end

  if destination then
    call_history.callee_account_type = common.str.to_sql(camelize_type(destination.type));
    call_history.callee_account_id = common.str.to_sql(destination.id);
    call_history.destination_number = common.str.to_sql(destination.number);
  end

  call_history.forwarding_service = common.str.to_sql(caller.forwarding_service);

  self.log:info('CALL_HISTORY_SAVE forwarded - account: ', account_type, '=', account_id,
    ', service: ', call_history.forwarding_service, 
    ', caller: ', call_history.caller_id_number, ' ', call_history.caller_id_name,
    ', callee: ', call_history.callee_id_number, ' ', call_history.callee_id_name,
    ', result: ', call_history.result
  );

  return self:insert_entry(call_history);
end
