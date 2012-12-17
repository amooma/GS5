-- Gemeinschaft 5 module: call forwarding class
-- (c) AMOOMA GmbH 2012
-- 

module(...,package.seeall)

CallForwarding = {}

-- Create CallForwarding object
function CallForwarding.new(self, arg, object)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self
  self.log = arg.log;
  self.database = arg.database;
  self.record = arg.record;
  self.domain = arg.domain;
  return object;
end

-- Find call forwarding by id
function CallForwarding.find_by_id(self, id)
  local sql_query = 'SELECT * FROM `call_forwards` WHERE `id`= ' .. tonumber(id) .. ' LIMIT 1';
  local record = nil

  self.database:query(sql_query, function(entry)
    record = entry;
  end)

  if record then
    call_forwarding = CallForwarding:new(self)
    call_forwarding.record = record
    return call_forwarding
  end

  return nil
end

function CallForwarding.presence_set(self, presence_state)
  require 'dialplan.presence'
  local presence = dialplan.presence.Presence:new();

  presence:init{log = self.log, accounts = { 'f-cftg-' .. tostring(self.record.id) }, domain = self.domain, uuid = 'call_forwarding_' ..  tostring(self.record.id)};

  return presence:set(presence_state);
end
