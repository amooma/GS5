-- Gemeinschaft 5 module: event manager class
-- (c) AMOOMA GmbH 2012
-- 

module(...,package.seeall)

EventManager = {}

-- create event manager object
function EventManager.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.class = 'eventmanager'
  self.database = arg.database;
  self.domain = arg.domain;

  return object;
end


function EventManager.register(self)
  self.consumer = freeswitch.EventConsumer('all');
  return (self.consumer ~= nil);
end


function EventManager.load_event_modules(self)
  require 'common.configuration_table'
  self.config = common.configuration_table.get(self.database, 'events');

  return self.config.modules;
end


function EventManager.load_event_handlers(self, event_modules)
  event_handlers = {}

  for event_module_name, index in pairs(event_modules) do
    event_module = require('event.' .. event_module_name);
    if event_module then
      self.log:info('[event] EVENT_MANAGER - loading handler module: ', event_module_name);
      handler_class = event_module.handler_class();

      if handler_class then
        module_event_handlers = handler_class:new{ log = self.log, database = self.database, domain = self.domain }:event_handlers();
        if module_event_handlers then
          for event_name, event_subclasses in pairs(module_event_handlers) do
            if not event_handlers[event_name] then
              event_handlers[event_name] = {};
            end

            for event_subclass, module_event_handler in pairs(event_subclasses) do
              if not event_handlers[event_name][event_subclass] then
                event_handlers[event_name][event_subclass] = {};
              end

              table.insert(event_handlers[event_name][event_subclass], { class = handler_class, method = module_event_handler } );
              self.log:info('[event] EVENT_MANAGER - module: ', event_module_name, ', handling events: ', event_name, ', subclass:', event_subclass);
            end
          end
        end
      end
    end
  end

  return event_handlers;
end


function EventManager.run(self)

  local event_modules = self:load_event_modules();
  local event_handlers = self:load_event_handlers(event_modules);

  if not event_handlers then
    self.log:error('[event] EVENT_MANAGER - no handlers specified');
    return nil;
  end

  if not self:register() then
    return nil;
  end

  freeswitch.setGlobalVariable('gs_event_manager', 'true');
  while freeswitch.getGlobalVariable('gs_event_manager') == 'true' do
    local event = self.consumer:pop(1, 100);
    if event then
      local event_type = event:getType();
      local event_subclass = event:getHeader('Event-Subclass');
      if event_handlers[event_type] then
        if event_handlers[event_type][event_subclass] and #event_handlers[event_type][event_subclass] > 0 then
          for index, event_handler in ipairs(event_handlers[event_type][event_subclass]) do
            event_handler.method(event_handler.class, event);
          end
        end
        if event_handlers[event_type][true] and #event_handlers[event_type][true] > 0 then
          for index, event_handler in ipairs(event_handlers[event_type][true]) do
            event_handler.method(event_handler.class, event);
          end
        end
      end
    end
  end
end
