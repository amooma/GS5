-- Gemeinschaft 5 module: sync log class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

SyncLog = {}

-- create sync log object
function SyncLog.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.database = arg.database;
  self.homebase_ip_address = arg.homebase_ip_address;
  return object;
end

-- create new entry
function SyncLog.insert(self, entry_name, entry_record, action, history_entries)
  local content = {}
  for key, value in pairs(entry_record) do
    require 'common.str'
    table.insert(content, '"'.. key ..'":' .. common.str.to_json(value));
  end
 
  local history = '';
  if action == 'update' then
    history = 'Changed: ["' .. table.concat(history_entries, '","') .. '"]';
  end

  local sql_query = 'INSERT INTO `gs_cluster_sync_log_entries` (`waiting_to_be_synced`,`created_at`,`updated_at`,`class_name`,`action`,`content`,`history`,`homebase_ip_address`) \
    VALUES \
    (TRUE, NOW(), NOW(), \'' .. entry_name .. '\', \'' .. action .. '\', \'{' .. table.concat(content, ',') .. '}\', \'' .. history .. '\',  \'' .. self.homebase_ip_address .. '\')';

  return self.database:query(sql_query);
end
