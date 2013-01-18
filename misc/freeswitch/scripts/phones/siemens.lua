-- Gemeinschaft 5 module: general siemens model class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

Siemens = {}

-- create siemens object
function Siemens.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.PHONE_HTTP_PORT = 8085;
  return object;
end

-- send reload message to phone
function Siemens.resync(self, arg)
  if arg.ip_address then
    return self:resync_http(arg.ip_address, arg.http_user, arg.http_password, arg.http_port);
  end

  return false;
end

-- send reload message to ip
function Siemens.resync_http(self, ip_address, http_user, http_password, http_port)
  local port_str = '';
  if tonumber(http_port) then
    port_str = ':' .. http_port;
  end

  get_command = 'wget --no-proxy -q -O /dev/null -o /dev/null -b --tries=2 --timeout=10 --user="' .. (http_user or '') .. '" --password="' .. (http_password or '') .. '"' ..
  ' wget http://' .. tostring(ip_address):gsub('[^0-9%.]', '') .. ':' .. (tonumber(http_port) or self.PHONE_HTTP_PORT) .. '/contact_dls.html/ContactDLS' ..
  ' 1>>/dev/null 2>>/dev/null &';

  result = os.execute(get_command);

  if result and tonumber(result) == 0  then
    return true;
  end
end
