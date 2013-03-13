-- Gemeinschaft 5 routing test module
-- (c) AMOOMA GmbH 2013
--

require 'common.array';

local arguments = {};
local value = nil;

for index=1, #argv do
  if math.mod(index, 2) == 0 then
    common.array.set(arguments, argv[index], value);
  else
    value = argv[index];
  end
end

local caller = arguments.caller or {};
local channel_variables = arguments.chv or {};

function caller.to_s(variable)
  return common.str.to_s(arguments[variable])
end

local log_buffer = {};
-- initialize logging
require 'common.log';
log = common.log.Log:new{ buffer = log_buffer, prefix = '' };

-- connect to database
require 'common.database';
local database = common.database.Database:new{ log = log }:connect();
if not database:connected() then
  log:critical('TEST_ROUTE - database connection failed');
  return;
end

-- dialplan object
require 'dialplan.dialplan'
local dialplan_object = dialplan.dialplan.Dialplan:new{ log = log, caller = caller, database = database };
dialplan_object:configuration_read();
caller.dialplan = dialplan_object;
caller.local_node_id = dialplan_object.node_id;

dialplan_object:retrieve_caller_data();
local destination = arguments.destination or dialplan_object:destination_new{ number = caller.destination_number };
local routes = {};

if destination and destination.type == 'unknown' then
  local clip_no_screening = common.array.try(caller, 'account.record.clip_no_screening');
  caller.caller_id_numbers = {}
  if not common.str.blank(clip_no_screening) then
    for index, number in ipairs(common.str.strip_to_a(clip_no_screening, ',')) do
      table.insert(caller.caller_id_numbers, number);
    end
  end
  if caller.caller_phone_numbers then
    for index, number in ipairs(caller.caller_phone_numbers) do
      table.insert(caller.caller_id_numbers, number);
    end
  end
  log:info('CALLER_ID_NUMBERS - clir: ', caller.clir, ', numbers: ', table.concat(caller.caller_id_numbers, ','));

  destination.callee_id_number = destination.number;
  destination.callee_id_name = nil;
end

require 'dialplan.router';
routes =  dialplan.router.Router:new{ log = log, database = database, caller = caller, variables = caller, log_details = true }:route_run(arguments.table or 'outbound');

local result = {
  routes = routes,
  destination = destination,
  log = log_buffer
}

stream:write(common.array.to_json(result));

-- release database handle
if database then
  database:release();
end
