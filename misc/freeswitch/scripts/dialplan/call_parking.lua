-- Gemeinschaft 5 module: call parking class
-- (c) AMOOMA GmbH 2013
-- 

module(...,package.seeall)

PARKING_STALL_FORMAT = '[0-9A-Z_%+%-]+';
UUID_FORMAT = '[0-9a-f%-]+';

CallParking = {}

-- create acd object
function CallParking.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.class = 'parkingstall';
  self.log = arg.log;
  self.database = arg.database;
  self.lot = arg.lot or 'default';
  self.caller = arg.caller;
  return object;
end


function CallParking.find_by_name(self, name)
  local sql_query = 'SELECT * FROM `parking_stalls` WHERE `name`= '.. self.database:escape(name, '"') .. ' LIMIT 1';
  local parking_stall = nil;

  self.database:query(sql_query, function(entry)
    parking_stall = CallParking:new(self);
    parking_stall.record = entry;
    parking_stall.id = tonumber(entry.id);
    parking_stall.name = entry.name;
  end)

  return parking_stall;
end


function CallParking.find_by_owner(self, owner_id, owner_type)
  local sql_query = 'SELECT * FROM `parking_stalls` WHERE `parking_stallable_id` = '.. owner_id .. ' AND `parking_stallable_type` = "' .. owner_type .. '" ORDER BY `name`';
  local parking_stalls = {};

  self.database:query(sql_query, function(entry)
    local parking_stall = CallParking:new(self);
    parking_stall.record = entry;
    parking_stall.id = tonumber(entry.id);
    parking_stall.name = entry.name;
    table.insert(parking_stalls, parking_stall)
  end)

  return parking_stalls;
end


function CallParking.list_occupied(self, lot)
  lot = lot or self.lot;

  require 'common.fapi'
  local valet_info = common.fapi.FApi:new{ log = self.log }:execute('valet_info', lot);

  local parking_stalls = {};
  tostring(valet_info):gsub('<extension uuid="(' .. UUID_FORMAT .. ')">(' .. PARKING_STALL_FORMAT .. ')</extension>', function(channel_uuid, parking_stall)
    parking_stalls[parking_stall] = channel_uuid;
  end);

  return parking_stalls;
end


function CallParking.occupied(self)
  local occupied_stalls = self:list_occupied();
  if occupied_stalls then
    return occupied_stalls[self.name];
  end
end


function CallParking.park_retrieve(self)
  self.caller:execute("valet_park",  self.lot .. ' ' .. self.name);
end


function CallParking.park(self)
  if self:occupied() then
    return false;
  end
  self.caller:execute("valet_park",  self.lot .. ' ' .. self.name);
end


function CallParking.retrieve(self)
  if not self:occupied() then
    return false;
  end
  self.caller:execute("valet_park",  self.lot .. ' ' .. self.name);
end
