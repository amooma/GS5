-- Gemeinschaft 5 module: dump_variables event handler class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)


function handler_class()
  return DumpVariables
end


DumpVariables = {}


function DumpVariables.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.class = 'DumpVariables'
  self.dump_file = arg.file or '/var/log/freeswitch/variables';

  return object;
end


function DumpVariables.event_handlers(self)
  return { CHANNEL_CREATE = { [true] = self.channel_data } }
end


function DumpVariables.channel_data(self, event)
  local sequence = event:getHeader('Event-Sequence');
  local direction = event:getHeader('Call-Direction');

  if not direction or direction ~= 'inbound' then
    return;
  end

  local file = io.open(self.dump_file, 'w');
  if not file then
    self.log:error('[', event.sequence, '] DUMP_VARIABLES - could not open file for writing: ', self.dump_file);
    return;
  end

  self.log:debug('[', event.sequence, '] DUMP_VARIABLES - dumping channel data to: ', self.dump_file);

  file:write(event:serialize(), '\n');
  file:close();
end
