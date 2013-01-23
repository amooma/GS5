-- Gemeinschaft 5 event handler
-- (c) AMOOMA GmbH 2012-2013
-- 

-- Set logger
require "common.log"
local log = common.log.Log:new()
log.prefix = "#E# "

log:info('[event] EVENT_MANAGER start');

require 'common.database'
local database = common.database.Database:new{ log = log }:connect();
if not database:connected() then
  log:error('[event] EVENT_MANAGER - cannot connect to Gemeinschaft database');
  return;
end

require "configuration.sip"
local domains = configuration.sip.Sip:new{ log = log, database = database }:domains();

local domain = '127.0.0.1';
if domains[1] then
  domain = domains[1]['host'];
else
  log:error('[event] EVENT_MANAGER - No SIP domains found!');
end

require 'event.event'
local event_manager = event.event.EventManager:new{ log = log, database = database, domain = domain }
event_manager:run();

-- ensure database handle is released on exit
if database then
  database:release();
end

log:info('[event] EVENT_MANAGER exit');
