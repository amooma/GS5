-- Gemeinschaft 5 module: perimeter defense event handler class
-- (c) AMOOMA GmbH 2013
--

module(...,package.seeall)

function handler_class()
  return PerimeterDefense
end

PerimeterDefense = {}

function PerimeterDefense.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.class = 'perimeterdefense'
  self.database = arg.database;
  self.domain = arg.domain;

  require 'common.perimeter';
  self.perimeter = common.perimeter.Perimeter:new(arg);
  self.perimeter:setup();

  return object;
end


function PerimeterDefense.event_handlers(self)
  return { CUSTOM = { 
    ['sofia::pre_register'] = self.sofia_pre_register,
    ['sofia::register_attempt'] = self.sofia_register_attempt,
    ['sofia::register_failure'] = self.sofia_register_failure,
  } }
end


function PerimeterDefense.to_record(self, event, class)
  return {
    class = class,
    key = event:getHeader('network-ip'),
    sequence = tonumber(event:getHeader('Event-Sequence')),
    timestamp = tonumber(event:getHeader('Event-Date-Timestamp')),
    received_ip = event:getHeader('network-ip'),
    received_port = event:getHeader('network-port'),
    from_user = event:getHeader('from-user'),
    from_host = event:getHeader('from-host'),
    to_user = event:getHeader('to-user'),
    to_host = event:getHeader('to-host'),
    user_agent = event:getHeader('user-agent'),
    user_agent = event:getHeader('user-agent'),
    username = event:getHeader('username'),
    realm = event:getHeader('realm'),
    auth_result = event:getHeader('auth-result'),
    contact = event:getHeader('contact'),
  };
end


function PerimeterDefense.sofia_pre_register(self, event)
  local record = self:to_record(event, 'pre_register');
  self.perimeter:check(record);
end


function PerimeterDefense.sofia_register_attempt(self, event)
  local record = self:to_record(event, 'register_attempt');
  self.perimeter:check(record);
end


function PerimeterDefense.sofia_register_failure(self, event)
  local record = self:to_record(event, 'register_failure');
  self.perimeter:check(record);
end
