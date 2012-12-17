-- Gemeinschaft 5 module: cdr event handler class
-- (c) AMOOMA GmbH 2012
-- 

module(...,package.seeall)


function handler_class()
  return CdrSave
end


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


CdrSave = {}


function CdrSave.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.class = 'cdrsave'
  self.database = arg.database;
  self.domain = arg.domain;

  return object;
end


function CdrSave.event_handlers(self)
  return { CHANNEL_DESTROY = { [true] = self.channel_destroy } }
end


function CdrSave.channel_destroy(self, event)
  local uuid = event:getHeader('Unique-ID');
  local direction = event:getHeader('variable_direction');

  require 'common.str'
  local save_cdr = common.str.to_b(event:getHeader('variable_gs_save_cdr'));

  if not save_cdr then
    self.log:debug('[', uuid,'] CDR_SAVE - event: CHANNEL_DESTROY, direction: ', direction, ', save_cdr: ', save_cdr);
    return false;
  end
  
  require 'common.str'
  local cdr = {}

  cdr.uuid = common.str.to_sql(uuid);
  cdr.bleg_uuid = common.str.to_sql(event:getHeader('variable_bridge_uuid'));
  cdr.dialed_number = common.str.to_sql(event:getHeader('Caller-Destination-Number'));
  cdr.destination_number = common.str.to_sql(event:getHeader('variable_gs_destination_number'));
  cdr.caller_id_number = common.str.to_sql(event:getHeader('variable_effective_caller_id_number'));
  cdr.caller_id_name = common.str.to_sql(event:getHeader('variable_effective_caller_id_name'));
  cdr.callee_id_number = common.str.to_sql(event:getHeader('variable_effective_callee_id_number'));
  cdr.callee_id_name = common.str.to_sql(event:getHeader('variable_effective_callee_id_name'));
  cdr.start_stamp = 'FROM_UNIXTIME(' .. math.floor(common.str.to_i(event:getHeader('Caller-Channel-Created-Time')) / 1000000) .. ')';
  cdr.answer_stamp = 'FROM_UNIXTIME(' .. math.floor(common.str.to_i(event:getHeader('Caller-Channel-Answered-Time')) / 1000000) .. ')';
  cdr.end_stamp = 'FROM_UNIXTIME(' .. math.floor(common.str.to_i(event:getHeader('Caller-Channel-Hangup-Time')) / 1000000) .. ')';
  cdr.bridge_stamp = common.str.to_sql(event:getHeader('variable_bridge_stamp'));
  cdr.duration = common.str.to_sql(event:getHeader('variable_duration'));
  cdr.billsec = common.str.to_sql(event:getHeader('variable_billsec'));
  cdr.hangup_cause = common.str.to_sql(event:getHeader('variable_hangup_cause'));
  cdr.dialstatus = common.str.to_sql(event:getHeader('variable_DIALSTATUS'));
  cdr.forwarding_number = common.str.to_sql(event:getHeader('variable_gs_forwarding_number'));
  cdr.forwarding_service = common.str.to_sql(event:getHeader('variable_gs_forwarding_service'));
  cdr.forwarding_account_id = common.str.to_sql(event:getHeader('variable_gs_auth_account_id'));
  cdr.forwarding_account_type = common.str.to_sql(camelize_type(event:getHeader('variable_gs_auth_account_type')));
  cdr.account_id = common.str.to_sql(event:getHeader('variable_gs_account_id'));
  cdr.account_type = common.str.to_sql(camelize_type(event:getHeader('variable_gs_account_type')));
  cdr.bleg_account_id = common.str.to_sql(event:getHeader('variable_gs_destination_id'));
  cdr.bleg_account_type = common.str.to_sql(camelize_type(event:getHeader('variable_gs_destination_type')));
  
  local keys = {}
  local values = {}

  for key, value in pairs(cdr) do
    table.insert(keys, key);
    table.insert(values, value);
  end

  self.log:info('[', uuid,'] CDR_SAVE - account: ', cdr.account_type, '=', cdr.account_id, 
    ', caller: ', cdr.caller_id_number, ' ', cdr.caller_id_name,
    ', callee: ', cdr.callee_id_number, ' ', cdr.callee_id_name,
    ', cause: ', cdr.hangup_cause
  );

  local sql_query = 'INSERT INTO `cdrs` (`' .. table.concat(keys, "`, `") .. '`) VALUES (' .. table.concat(values, ", ") .. ')';
  return self.database:query(sql_query);
end
