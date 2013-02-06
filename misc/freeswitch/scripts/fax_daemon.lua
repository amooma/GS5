-- Gemeinschaft 5 fax daemon
-- (c) AMOOMA GmbH 2012-2013
-- 

local MAIN_LOOP_SLEEP_TIME = 30;

-- Set logger
require 'common.log'
local log = common.log.Log:new()
log.prefix = '#F# [faxdaemon] '

log:info('FAX_DAEMON start');

require 'common.database'
local database = common.database.Database:new{ log = log }:connect();
if not database:connected() then
  log:error('FAX_DAEMON - cannot connect to Gemeinschaft database');
  return;
end

local api = freeswitch.API();
require 'dialplan.fax'
freeswitch.setGlobalVariable('gs_fax_daemon', 'true');

while freeswitch.getGlobalVariable("gs_fax_daemon") == 'true' do
  local fax_documents = dialplan.fax.Fax:new{log=log, database=database}:queued_for_sending();

  for key, fax_document in pairs(fax_documents) do
    if table.getn(fax_document.destination_numbers) > 0 and tonumber(fax_document.retry_counter) > 0 then
      log:debug('FAX_DAEMON_LOOP - fax_document=', fax_document.id, '/', fax_document.uuid, ', number: ' .. fax_document.destination_numbers[1]);
      local result = api:executeString('luarun send_fax.lua ' .. fax_document.id);
    end
  end
  
  if freeswitch.getGlobalVariable("gs_fax_daemon") == 'true' then
    freeswitch.msleep(MAIN_LOOP_SLEEP_TIME * 1000);
  end
end

database:release();
log:info('FAX_DAEMON exit');
