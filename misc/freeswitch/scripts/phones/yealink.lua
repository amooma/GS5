-- Gemeinschaft 5 module: general yealink model class
-- (c) AMOOMA GmbH 2013
-- 

module(...,package.seeall)

Yealink = {}

-- Create Yealink object
function Yealink.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.reboot = arg.reboot or true;
  return object;
end

-- send reload message to phone
function Yealink.resync(self, arg)
  if arg.reboot == nil then
    arg.reboot = self.reboot;
  end

  local success = nil;
  if arg.auth_name and arg.domain then
    success = self:resync_sip(arg.auth_name, arg.domain, arg.reboot);
  end

  if arg.ip_address and arg.reboot then
    success = self:resync_http(arg.ip_address, arg.http_user, arg.http_password, arg.http_port);
  end

  return success;
end

-- send reload message to sip_account
function Yealink.resync_sip(self, sip_account, domain, reboot)
  local event = freeswitch.Event('NOTIFY');
  event:addHeader('profile', 'gemeinschaft');
  event:addHeader('event-string', 'check-sync;reboot=' .. tostring(reboot));
  event:addHeader('user', sip_account);
  event:addHeader('host', domain);
  event:addHeader('content-type', 'application/simple-message-summary');
  return event:fire();
end

-- send reload message to ip
function Yealink.resync_http(self, ip_address, http_user, http_password, http_port)
  local port_str = '';
  if tonumber(http_port) then
    port_str = ':' .. http_port;
  end

  local command = 'http_request.lua yealink_resync http://' .. tostring(ip_address):gsub('[^0-9%.]', '') .. port_str .. '/cgi-bin/ConfigManApp.com?key=Reboot ' .. (http_user or '') .. ' ' .. (http_password or '');

  require 'common.fapi'
  return common.fapi.FApi:new():execute('luarun', command);
end
