-- Gemeinschaft 5 module: general snom model class
-- (c) AMOOMA GmbH 2012
-- 

module(...,package.seeall)

Snom = {}

-- Create Snom object
function Snom.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.reboot = arg.reboot or true;
  return object;
end

-- send reload message to phone
function Snom.resync(self, arg)
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
function Snom.resync_sip(self, sip_account, domain, reboot)
  local event = freeswitch.Event('NOTIFY');
  event:addHeader('profile', 'gemeinschaft');
  event:addHeader('event-string', 'check-sync;reboot=' .. tostring(reboot));
  event:addHeader('user', sip_account);
  event:addHeader('host', domain);
  event:addHeader('content-type', 'application/simple-message-summary');
  return event:fire();
end

-- send reload message to ip
function Snom.resync_http(self, ip_address, http_user, http_password, http_port)
  local port_str = '';
  if tonumber(http_port) then
    port_str = ':' .. http_port;
  end

  get_command = 'wget --no-proxy -q -O /dev/null -o /dev/null -b --tries=2 --timeout=10 --user="' .. (http_user or '') .. '" --password="' .. (http_password or '') .. '"' ..
  ' wget http://' .. tostring(ip_address):gsub('[^0-9%.]', '') .. port_str .. '/advanced.htm?reboot=Reboot' ..
  ' 1>>/dev/null 2>>/dev/null &';

  result = os.execute(get_command);

  if result and tonumber(result) == 0  then
    return true;
  end
end
