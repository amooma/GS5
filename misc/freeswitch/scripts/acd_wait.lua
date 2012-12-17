-- Gemeinschaft 5: acd call handler
-- (c) AMOOMA GmbH 2012
-- 

local caller_uuid    = argv[1];
local acd_id        = tonumber(argv[2]);
local timeout       = tonumber(argv[3]);
local retry_timeout = tonumber(argv[4]);
local acd_caller_id = tonumber(argv[5]);

-- initialize logging
require 'common.log'
local log = common.log.Log:new{ prefix = '### [' .. caller_uuid .. '] ' };

if not acd_id then
  log:error('ACD_WAIT - automaticcalldistributor=', acd_id, ' not specified');
  return;
end

-- connect to database
require 'common.database'
local database = common.database.Database:new{ log = log }:connect();
if not database:connected() then
  log:critical('ACD_WAIT - database connect failed');
  database:release();
  return;
end

require 'dialplan.acd'
local acd = dialplan.acd.AutomaticCallDistributor:new{ log = log, database = database }:find_by_id(acd_id);

if not acd then
  log:error('ACD_WAIT - automaticcalldistributor=', acd_id, ' not found');
  database:release();
  return;
end

log:debug('ACD_WAIT ', acd_id, ' - start');
acd:wait_turn(caller_uuid, acd_caller_id, timeout, retry_timeout);
log:debug('ACD_WAIT ', acd_id, ' - end');

-- release database
if database then
  database:release();
end
