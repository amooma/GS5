-- Gemeinschaft 5 module: general gigaset model class
-- (c) Peter Kozak 2013
-- 

module(...,package.seeall)

Gigaset = {}

-- Create Gigaset object
function Gigaset.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.reboot = arg.reboot or true;
  return object;
end

-- send reload message to phone
function Gigaset.resync(self, arg)
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
function Gigaset.resync_sip(self, sip_account, domain, reboot)
  local event = freeswitch.Event('NOTIFY');
  event:addHeader('profile', 'gemeinschaft');
  event:addHeader('event-string', 'check-sync;reboot=' .. tostring(reboot));
  event:addHeader('user', sip_account);
  event:addHeader('host', domain);
  event:addHeader('content-type', 'application/simple-message-summary');
  return event:fire();
end

-- send reload message to phpne ip
function Gigaset.resync_http(self, ip_address, http_user, http_password, http_port)
  return nil;
end
