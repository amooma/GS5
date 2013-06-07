-- Gemeinschaft 5 module: pager class
-- (c) AMOOMA GmbH 2013
-- 

module(...,package.seeall)

Pager = {}

function Pager.new(self, arg)
  arg = arg or {}
  pager = arg.pager or {}
  setmetatable(pager, self);
  self.__index = self;
  self.class = 'pager';
  self.log = arg.log;
  self.database = arg.database;
  self.caller = arg.caller;

  return pager;
end


function Pager.find_by_id(self, id)
  local sql_query = 'SELECT * FROM `pager_groups` WHERE `id`= '.. tonumber(id) .. ' LIMIT 1';
  local pager = nil;

  self.database:query(sql_query, function(entry)
    pager = Pager:new(self);
    pager.record = entry;
    pager.id = tonumber(entry.id);
    pager.uuid = entry.uuid;
    pager.identifier = 'pager' .. entry.id;
  end)

  return pager;
end


function Pager.enter(self)
  local flags = 'mute';

  if not self.caller.account or self.caller.account.class ~= 'sipaccount'  then
    return false;
  end

  if tonumber(self.record.sip_account_id) == tonumber(self.caller.account.id) then
    flags = 'moderator|endconf';
  end

  self:callback();

  local result = self.caller:execute('conference', self.identifier .. "@profile_" .. self.identifier .. "++flags{" .. flags .. "}");
  self.caller:hangup('NORMAL_CLEARING');
  self:callback();
end


function Pager.callback(self)
  local destination = {
    pager_group_id = self.id,
    state = 'terminated',
  }

  if self.caller.account and self.caller.account.class == 'sipaccount' then
    destination.sip_account_id = self.caller.account.id;
  end

  if self.caller and self.caller:ready() then
    destination.state = 'active';
  end

  local command = 'http_request.lua ' .. self.caller.uuid .. ' ' .. common.array.expand_variables(self.record.callback_url, destination, self.caller);
  require 'common.fapi';
  return common.fapi.FApi:new():execute('luarun', command);
end
