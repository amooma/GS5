-- Gemeinschaft 5 default dialplan
-- (c) AMOOMA GmbH 2012-2013
-- 


function hangup_hook_caller(s, status, arg)
  log:info('HANGUP_HOOK: ', status)
  if tostring(status) == 'transfer' then
    if start_caller and start_caller.destination then
      log:info('CALL_TRANSFERRED - destination was: ', start_caller.destination.type, '=', start_caller.destination.id,', number: ' .. tostring(start_caller.destination.number) .. ', to: ' .. start_caller:to_s('sip_refer_to'));
      start_caller.auth_account            = start_caller.dialplan:object_find(start_caller.destination.type, start_caller.destination.id);
      start_caller.forwarding_number       = start_caller.destination.number;
      start_caller.forwarding_service      = 'transfer';
    end
  end
end

function input_call_back_caller(s, object_type, object_data, arg)
  if object_type == 'dtmf' then
    require 'dialplan.dtmf'
    local dtmf = dialplan.dtmf.Dtmf:new{ log = log, router = dtmf_router }:detect(start_caller, start_caller.dtmf, object_data.digit, object_data.duration);
  end
end

function input_call_back_callee(s, object_type, object_data, arg)
  if object_type == 'dtmf' then
    require 'dialplan.dtmf'
    local dtmf = dialplan.dtmf.Dtmf:new{ log = log, router = dtmf_router }:detect(start_caller, start_caller.dtmf_callee, object_data.digit, object_data.duration, true);
  end
end


-- initialize logging
require 'common.log'
log = common.log.Log:new{ prefix = '### [' .. session:get_uuid() .. '] ' };

-- caller session object
require 'dialplan.session'
start_caller = dialplan.session.Session:new{ log = log, session = session };

-- connect to database
require 'common.database'
local database = common.database.Database:new{ log = log }:connect();
if not database:connected() then
  log:critical('DIALPLAN_DEFAULT - database connect failed');
  return;
end

-- dialplan object
require 'dialplan.dialplan'

local start_dialplan = dialplan.dialplan.Dialplan:new{ log = log, caller = start_caller, database = database };
start_dialplan:configuration_read();
start_caller.dialplan = start_dialplan;
start_caller.local_node_id = start_dialplan.node_id;
start_caller:init_channel_variables();
start_caller.dtmf = {
  updated = os.time(),
  digits = '';
};
start_caller.dtmf_callee = {
  updated = os.time(),
  digits = '';
};

if start_dialplan.config.parameters.dump_variables then
  start_caller:execute('info', 'notice');
end

if start_caller.from_node and not start_dialplan:auth_node() then
  log:debug('DIALPLAN_DEFAULT - node unauthorized - node_id: ', start_caller.node_id, ', domain: ', start_dialplan.domain);
  start_dialplan:hangup(401, start_dialplan.domain);
else
  if not start_dialplan:auth_sip_account() then
    local gateway = start_dialplan:auth_gateway()

    if gateway then
      start_caller.gateway_name = gateway.name;
      start_caller.gateway_id = gateway.id;
      start_caller.from_gateway = true;
      start_caller.gateway = gateway;
    else
      log:debug('AUTHENTICATION_REQUIRED_SIP_ACCOUNT - contact host: ' , start_caller.sip_contact_host, ', ip: ', start_caller.sip_network_ip, ', domain: ', start_dialplan.domain);
      start_dialplan:hangup(407, start_dialplan.domain);
      if database then
        database:release();
      end
      return;
    end
  end
end

if start_caller.from_node then
  log:debug('AUTHENTICATION_REQUIRED_NODE - node_id: ', start_caller.node_id, ', domain: ', start_dialplan.domain);
  start_dialplan:hangup(407, start_dialplan.domain);
else
  start_destination = { type = 'unknown' }
  start_caller.session:setHangupHook('hangup_hook_caller', 'destination_number');
  
  require 'dialplan.router'
  dtmf_router =  dialplan.router.Router:new{ log = log, database = database, caller = start_caller, variables = start_caller };
  start_dialplan.dtmf_detection = #dtmf_router:read_table('dtmf') > 0;

  if start_dialplan.dtmf_detection then
    start_dialplan.detect_dtmf_after_bridge_caller = true;
    start_dialplan.detect_dtmf_after_bridge_callee = true;
    start_caller.session:setInputCallback('input_call_back_caller', 'start_dialplan');
  end

  start_dialplan:run(start_destination);
end

-- release database handle
if database then
  database:release();
end
