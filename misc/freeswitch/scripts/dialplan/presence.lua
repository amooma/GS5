-- Gemeinschaft 5 module: presence class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

Presence = {}

-- Create Presence object
function Presence.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self)
  self.__index = self
  self.log = arg.log;
  self.domain = arg.domain;
  self.uuid = arg.uuid;
  self.inbound = arg.inbound;
  self.accounts = arg.accounts;

  return object
end


function Presence.init(self, arg)
  self.log = arg.log or self.log;
  self.domain = arg.domain or self.domain;
  self.uuid = arg.uuid or self.uuid;
  self.inbound = arg.inbound or self.inbound;
  self.accounts = arg.accounts or self.accounts;
end


function Presence.set(self, state, caller_number)
  if not self.accounts or #self.accounts == 0 then
    return nil;
  end

  state = state or "terminated";
  local direction = "outbound";
  
  if self.inbound then
    direction = "inbound";
  end

  for index, account in pairs(self.accounts) do
    if account ~= '' then
      local event = freeswitch.Event('PRESENCE_IN');
      event:addHeader('proto', 'sip');
      event:addHeader('from', account .. '@' .. self.domain);
      event:addHeader('event_type', 'presence');
      event:addHeader('alt_event_type', 'dialog');
      event:addHeader('presence-call-direction', direction);
      event:addHeader('answer-state', state);
      event:addHeader('unique-id', self.uuid);
      if caller_number then
        if self.inbound then
          event:addHeader('Caller-Destination-Number', caller_number);
        else
          event:addHeader('Other-Leg-Caller-ID-Number', caller_number);
        end
      end
      event:fire();
      self.log:debug('PRESENCE - account: ' .. account .. '@' .. self.domain .. ', state: ' .. state .. ', direction: ' .. direction .. ', uid: ' ..self.uuid);
    end
  end

  return true;
end


function Presence.early(self, caller_number)
  return self:set("early", caller_number);
end


function Presence.confirmed(self, caller_number)
  return self:set("confirmed", caller_number);
end


function Presence.terminated(self, caller_number)
  return self:set("terminated", caller_number);
end
