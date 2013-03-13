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

-- initialize logging
require 'common.log';
log = common.log.Log:new{ disabled = true };

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

require 'dialplan.router';
local routes =  dialplan.router.Router:new{ log = log, database = database, caller = caller, variables = caller }:route_run(arguments.table or 'outbound');

local result = {
  routes = routes
}

stream:write(common.array.to_json(result));

-- release database handle
if database then
  database:release();
end
