-- Gemeinschaft 5 module: snom vision extension module model class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

SnomVision = {}

-- Create SnomVision object
function SnomVision.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.reboot = arg.reboot or true;
  return object;
end

-- send reload message to module
function SnomVision.resync(self, arg)
  if arg.ip_address then
    return self:resync_http(arg.ip_address, arg.http_user, arg.http_password, arg.http_port);
  end

  return false;
end


function SnomVision.resync_http(self, ip_address, http_user, http_password, http_port)
  local port_str = '';
  if tonumber(http_port) then
    port_str = ':' .. http_port;
  end

  local command = 'http_request.lua snom_vision_resync http://' .. tostring(ip_address):gsub('[^0-9%.]', '') .. port_str .. '/ConfigurationModule/restart ' .. (http_user or '') .. ' ' .. (http_password or '');
  require 'common.fapi'
  return common.fapi.FApi:new():execute('luarun', command);
end
