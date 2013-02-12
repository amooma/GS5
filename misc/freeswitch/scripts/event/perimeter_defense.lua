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
  return { 
    CUSTOM = { 
    ['sofia::pre_register'] = self.sofia_pre_register,
    ['sofia::register_attempt'] = self.sofia_register_attempt,
    ['sofia::register_failure'] = self.sofia_register_failure,
    },
    CHANNEL_HANGUP = { [true] = self.channel_hangup },
  };
end


function PerimeterDefense.to_register_record(self, event, class)
  return {
    action = 'register',
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
    username = event:getHeader('username'),
    realm = event:getHeader('realm'),
    auth_result = event:getHeader('auth-result'),
    contact = event:getHeader('contact'),
  };
end


function PerimeterDefense.to_call_record(self, event, class)
  return {
    action = 'call',
    class = class,
    key = event:getHeader('Caller-Network-Addr'),
    sequence = tonumber(event:getHeader('Event-Sequence')),
    timestamp = tonumber(event:getHeader('Event-Date-Timestamp')),
    received_ip = event:getHeader('Caller-Network-Addr'),
    received_port = event:getHeader('variable_sip_network_port'),
    hangup_cause = event:getHeader('Hangup-Cause'),
    endpoint_disposition = event:getHeader('variable_endpoint_disposition'),
    direction = event:getHeader('Call-Direction'),
    destination_number = event:getHeader('Caller-Destination-Number');
    caller_id_name = event:getHeader('Caller-Caller-ID-Name');
    caller_id_number = event:getHeader('Caller-Caller-ID-Number');
    from_user = event:getHeader('variable_sip_from_user'),
    from_host = event:getHeader('variable_sip_from_host'),
    to_user = event:getHeader('variable_sip_to_user'),
    to_host = event:getHeader('variable_sip_to_host'),
    req_user = event:getHeader('variable_sip_req_user'),
    req_host = event:getHeader('variable_sip_req_host'),
    user_agent = event:getHeader('variable_sip_user_agent'),
    username = event:getHeader('Caller-Username'),
    contact = event:getHeader('variable_sip_contact_uri'),
  };
end


function PerimeterDefense.sofia_pre_register(self, event)
  local record = self:to_register_record(event, 'pre_register');
  self.perimeter:check(record);
end


function PerimeterDefense.sofia_register_attempt(self, event)
  local record = self:to_register_record(event, 'register_attempt');
  self.perimeter:check(record);
end


function PerimeterDefense.sofia_register_failure(self, event)
  local record = self:to_register_record(event, 'register_failure');
  self.perimeter:check(record);
end


function PerimeterDefense.channel_hangup(self, event)
  local record = self:to_call_record(event, 'channel_hangup');
  self.perimeter:check(record);
end
