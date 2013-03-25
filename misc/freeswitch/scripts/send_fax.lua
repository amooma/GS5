-- Gemeinschaft 5
-- (c) AMOOMA GmbH 2012-2013
-- 

local FAX_ANSWERING_TIMEOUT = 20;

-- Set logger
require 'common.log'
local log = common.log.Log:new()
log.prefix = '#F# [sendfax] '

local document_id = argv[1];

require 'common.database'
local database = common.database.Database:new{ log = log }:connect();

if not database:connected() then
  log:error('FAX_SEND - cannot connect to Gemeinschaft database');
  return
end

if not tonumber(document_id) then
  log:error('FAX_SEND - document id not specified');
  return
end

local defaults = {log=log, database=database}
require "dialplan.fax"
local fax_class = dialplan.fax.Fax:new(defaults);

local fax_document = fax_class:find_document_by_id(document_id);

if not fax_document then
  log:error('FAX_SEND - document ' .. document_id .. ' not found');
  return
end

if tonumber(fax_document.retry_counter) > 0 then
  fax_class:document_update(document_id, {state = 'sending', retry_counter = fax_document.retry_counter - 1});
else
  fax_class:document_update(document_id, {state = 'sending'});
end

local fax_account = fax_class:find_by_id(fax_document.fax_account_id);

if not fax_account then
  log:error('FAX_SEND - fax account ' .. fax_document.fax_account_id .. ' not found');
  return
end

local destination_number = fax_class:destination_number(document_id);

if not destination_number or tostring(destination_number) == '' then
  log:error('FAX_SEND - destination number not found');
  return
end

require 'common.str'
destination_number = common.str.strip(destination_number);

log:info('FAX_SEND - fax_document=' .. document_id .. ', destination number: ' .. destination_number .. ', retries: ' .. fax_document.retry_counter);

require "common.phone_number"
local phone_number_class = common.phone_number.PhoneNumber:new(defaults);

phone_number = phone_number_class:find_by_number(destination_number);

local origination_variables = {
  'gs_account_id='          .. fax_account.record.id,
  'gs_account_uuid='        .. fax_account.record.uuid,
  'gs_account_type='        .. 'faxaccount',
  'gs_auth_account_id='     .. fax_account.record.id,
  'gs_auth_account_uuid='   .. fax_account.record.uuid,
  'gs_auth_account_type='   .. 'faxaccount',
}

local caller = {
  destination_number = destination_number,
  account_type = 'faxaccount', 
  account_uuid = fax_account.uuid,
  auth_account_type = 'faxaccount', 
  auth_account_uuid = fax_account.uuid,
}

require 'dialplan.dialplan'
local dialplan = dialplan.dialplan.Dialplan:new{ log = log, caller = caller, database = database };
local result = dialplan:retrieve_caller_data();

caller.caller_id_numbers = {}
if not caller.clir then
  for index, number in ipairs(caller.caller_phone_numbers) do
    table.insert(caller.caller_id_numbers, number);
  end
  caller.caller_id_name = fax_account.record.station_id;
  caller.caller_id_number = caller.caller_id_numbers[1];
  table.insert(origination_variables, "sip_h_Privacy='none'");
else
  caller.caller_id_name = 'anonymous';
  caller.caller_id_number = 'anonymous';
  table.insert(origination_variables, "sip_h_Privacy='id'");
end

log:info('CALLER_ID_NUMBERS - clir: ', caller.clir, ', numbers: ', table.concat(caller.caller_id_numbers, ','));

local session = nil

if phone_number then
  table.insert(origination_variables, "origination_caller_id_number='" .. caller.caller_id_number .. "'");
  table.insert(origination_variables, "origination_caller_id_name='" .. caller.caller_id_name .. "'");
  session = freeswitch.Session("[" .. table.concat(origination_variables, ",") .. "]loopback/" .. destination_number .. "/default");
else
  local dialplan_router = require('dialplan.router');
  local routes =  dialplan_router.Router:new{ log = log, database = database, caller = caller, variables = caller }:route_run('outbound');
      
  if not routes or #routes == 0 then
    log:notice('SWITCH - no route - number: ', destination_number);
    return { continue = false, code = 404, phrase = 'No route' }
  end

  for index, route in ipairs(routes) do
    log:info('FAX_SEND - ', route.type, '=', route.id, '/', route.gateway,', number: ', route.destination_number);
    if route.type == 'gateway' then
      table.insert(origination_variables, "origination_caller_id_number='" .. (route.caller_id_number or caller.caller_id_number) .. "'");
      table.insert(origination_variables, "origination_caller_id_name='" .. (route.caller_id_name or caller.caller_id_name) .. "'");
      session = freeswitch.Session('[' .. table.concat(origination_variables, ',') .. ']sofia/gateway/' .. route.gateway .. '/' .. route.destination_number);
      log:notice('SESSION: ', session);
      break;
    end
  end
end

local loop_count = FAX_ANSWERING_TIMEOUT;
local cause = "UNSPECIFIED"

while session and session:ready() and not session:answered() and loop_count >= 0 do
  log:debug('waiting for answer: ' .. loop_count)
  loop_count = loop_count - 1;
  freeswitch.msleep(1000);
end

if session and session:answered() then
  log:info('FAX_SEND - sending fax_document=' .. fax_document.id .. ' (' .. fax_document.tiff .. ')');

  session:setVariable('fax_ident',   fax_account.record.station_id)
  session:setVariable('fax_header',  fax_account.record.name)
  session:setVariable('fax_verbose', 'false')
  local start_time = os.time();
  session:execute('txfax', fax_document.tiff);
  
  fax_state = {
    state = nil,
    transmission_time = os.time() - start_time,
    document_total_pages = common.str.to_i(session:getVariable('fax_document_total_pages')),
    document_transferred_pages = common.str.to_i(session:getVariable('fax_document_transferred_pages')),
    ecm_requested = common.str.to_b(session:getVariable('fax_ecm_requested')),
    ecm_used = common.str.to_b(session:getVariable('fax_ecm_used')),
    image_resolution = common.str.to_s(session:getVariable('fax_image_resolution')),
    image_size = common.str.to_i(session:getVariable('fax_image_size')),
    local_station_id = common.str.to_s(session:getVariable('fax_local_station_id')),
    result_code = common.str.to_i(session:getVariable('fax_result_code')),
    remote_station_id = common.str.to_s(session:getVariable('fax_remote_station_id')),
    success = common.str.to_b(session:getVariable('fax_success')),
    transfer_rate = common.str.to_i(session:getVariable('fax_transfer_rate')),   
  }

  if fax_state.success then
    fax_state.state = 'successful';
  else
    fax_state.state = 'unsuccessful';
  end

  fax_account:document_update(fax_document.id, fax_state)

  cause = session:hangupCause();
  log:info('FAX_SEND - end - fax_document=', fax_document.id, ', success: ', fax_state.state, ', cause: ', cause, ', result: ', fax_state.result_code, ' ', session:getVariable('fax_result_text'));

  local command = 'http_request.lua sendfax http://127.0.0.1/trigger/fax_has_been_sent/' .. tostring(fax_document.id);

  require 'common.fapi'
  common.fapi.FApi:new():execute('luarun', command);

else
  if session then 
    cause = session:hangupCause();
  end
  log:debug('Destination "', destination_number, '" could not be reached, cause: ', cause)
  fax_account:document_update(fax_document.id, {state = 'unsuccessful', result_code = "129"})
end
