-- Gemeinschaft 5 module: log
-- (c) AMOOMA GmbH 2012
-- 

module(...,package.seeall)

Log = {}

-- Create logger object
function Log.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.prefix = arg.prefix or '### ';

  self.level_console  = arg.level_console  or 0;
  self.level_alert    = arg.level_alert    or 1;
  self.level_critical = arg.level_critical or 2;
  self.level_error    = arg.level_error    or 3;
  self.level_warning  = arg.level_warning  or 4;
  self.level_notice   = arg.level_notice   or 5;
  self.level_info     = arg.level_info     or 6;
  self.level_debug    = arg.level_debug    or 7;

  return object;
end

function Log.message(self, log_level, message_arguments )
  local message = tostring(self.prefix);
  for index, value in pairs(message_arguments) do
    if type(index) == 'number' then
      message = message .. tostring(value);
    end
  end
  freeswitch.consoleLog(log_level, message .. '\n');
end

function Log.console(self, ...)
  self:message(self.level_console, arg);
end

function Log.alert(self, ...)
  self:message(self.level_alert, arg);
end

function Log.critical(self, ...)
  self:message(self.level_critical, arg);
end

function Log.error(self, ...)
  self:message(self.level_error, arg);
end

function Log.warning(self, ...)
  self:message(self.level_warning, arg);
end

function Log.notice(self, ...)
  self:message(self.level_notice, arg);
end

function Log.info(self, ...)
  self:message(self.level_info, arg);
end

function Log.debug(self, ...)
  self:message(self.level_debug, arg);
end
