-- Gemeinschaft 5 module: cdr event handler class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)


function handler_class()
  return Perimeter
end



Perimeter = {}

MALICIOUS_CONTACT_COUNT = 20;
MALICIOUS_CONTACT_TIME_SPAN = 2;
BAN_FUTILE = 2;

function Perimeter.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.class = 'cdrsave'
  self.database = arg.database;
  self.domain = arg.domain;

  self.ip_address_table = {}
  self:init();

  return object;
end


function Perimeter.event_handlers(self)
  return { CUSTOM = { ['sofia::pre_register'] = self.sofia_pre_register } }
end


function Perimeter.init(self)
  require 'common.configuration_table';
  local config = common.configuration_table.get(self.database, 'perimeter');
  if config and config.general then
    self.malicious_contact_count = tonumber(config.general.malicious_contact_count) or MALICIOUS_CONTACT_COUNT;
    self.malicious_contact_time_span = tonumber(config.general.malicious_contact_time_span) or MALICIOUS_CONTACT_TIME_SPAN;
    self.ban_futile = tonumber(config.general.ban_futile) or BAN_FUTILE;
    self.execute = config.general.execute;
  end

  self.log:info('[perimeter] PERIMETER - setup perimeter defense - config: ', self.malicious_contact_count, '/', self.malicious_contact_time_span, ', execute: ', self.execute);
end


function Perimeter.sofia_pre_register(self, event)
  local ip_address = event:getHeader('network-ip');
  self:check_ip(ip_address);
end


function Perimeter.check_ip(self, ip_address)
  local event_time = os.time();

  if not self.ip_address_table[ip_address] then
    self.ip_address_table[ip_address] = { last_contact = event_time, contact_count = 0, start_stamp = event_time, banned = 0 }
  end

  local ip_record = self.ip_address_table[ip_address];
  ip_record.last_contact = event_time;
  ip_record.contact_count = ip_record.contact_count + 1;

  if ip_record.contact_count > MALICIOUS_CONTACT_COUNT then
    if (event_time - ip_record.start_stamp) <= MALICIOUS_CONTACT_TIME_SPAN then
      self.log:warning('[', ip_address, '] PERIMETER - too many registration attempts');
      ip_record.start_stamp = event_time;
      ip_record.contact_count = 0;
      if ip_record.banned < BAN_FUTILE then
        ip_record.banned = ip_record.banned + 1;
        self:ban_ip(ip_address);
      else
        self.log:error('[', ip_address, '] PERIMETER - ban futile');
      end
    end
  end
end


function Perimeter.ban_ip(self, ip_address)
  self.ip_address = ip_address;

  if self.execute then
    local command = self:expand_variables(self.execute);
    self.log:debug('[', ip_address, '] PERIMETER - execute: ', command);
    local result = os.execute(command);
    if tostring(result) == '0' then
      self.log:warning('[', ip_address, '] PERIMETER - IP banned');
    end
  end
end


function Perimeter.expand_variables(self, line)
  return (line:gsub('{([%a%d_-]+)}', function(captured)
    return self[captured];
  end))
end
