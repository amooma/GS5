-- Gemeinschaft 5.0 fax daemon
-- (c) AMOOMA GmbH 2012
-- 

local MAIN_LOOP_SLEEP_TIME = 30;

-- Set logger
require "common.log"
local log = common.log.Log:new()
log.prefix = "### [faxdaemon] "

log:debug('Starting fax daemon');

local database = nil;
local api = freeswitch.API();

freeswitch.setGlobalVariable('gs_fax_daemon', 'true');
while freeswitch.getGlobalVariable("gs_fax_daemon") == 'true' do
  require 'common.database'
  local database = common.database.Database:new{ log = log }:connect();

  if not database:connected() then
    log:error("connection to Gemeinschaft database lost - retry in " .. MAIN_LOOP_SLEEP_TIME .. " seconds")
  else
    require 'dialplan.fax'
    local fax_documents = dialplan.fax.Fax:new{log=log, database=database}:queued_for_sending();

    for key, fax_document in pairs(fax_documents) do
      if table.getn(fax_document.destination_numbers) > 0 and tonumber(fax_document.retry_counter) > 0 then
        log:debug('FAX_DAEMON_LOOP - fax_document=', fax_document.id, '/', fax_document.uuid, ', number: ' .. fax_document.destination_numbers[1]);
        local result = api:executeString('luarun send_fax.lua ' .. fax_document.id);
      end
    end
  end
  database:release();

  if freeswitch.getGlobalVariable("gs_fax_daemon") == 'true' then
    freeswitch.msleep(MAIN_LOOP_SLEEP_TIME * 1000);
  end
end

log:debug('Exiting fax daemon');
