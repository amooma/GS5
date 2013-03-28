-- Gemeinschaft 5 module: callback class
-- (c) AMOOMA GmbH 2013
-- 

module(...,package.seeall)

Callback = {}

-- create callback callback ;)
function Callback.new(self, arg)
  arg = arg or {}
  callback = arg.callback or {}
  setmetatable(callback, self);
  self.__index = self;
  self.class = 'callback';
  self.log = arg.log;
  self.session = arg.session;
  self.sessions = {};
  local id = common.str.to_i(self.session);
  self.sessions[id] = { id = id, session = self.session, dtmf = {} };
  return callback;
end


function Callback.callback(self, class, identifier, callback_function, callback_instance, callback_session)
  local id = common.str.to_i(callback_session or self.session);
  local session_record = self.sessions[id];

  if not session_record and callback_session then
    self.sessions[id] = { id = id, session = callback_session, dtmf = {} };
    session_record = self.sessions[id];
  end
  
  if not session_record then
    return false;
  end


  _G['global_callback_record_' .. id] = session_record;

  session_record.session:setInputCallback('global_callback_handler', 'global_callback_record_' .. id);
  session_record[class][identifier] = { method = callback_function, instance = callback_instance };

  return true;
end


function Callback.callback_unset(self, class, identifier, callback_session)
 local session_record = self.sessions[common.str.to_i(callback_session or self.session)];
  if not session_record then
    return false;
  end

  -- session_record.session:unsetInputCallback();
  session_record[class][identifier] = nil;

  return true;
end


function Callback.run(self, arg)
  local identifier = arg[2];
  local data = arg[3];
  local session_record = arg[4];
  local callbacks = session_record[identifier];

  local return_value = nil;
  if callbacks then
    for identifier, callback in pairs(callbacks) do
      if callback.method then
        local result = nil;
        if callback.instance then
          result = callback.method(callback.instance, data);
        else
          result = callback.method(data.digit, data);
        end
        if result == false then
          return_value = 'break';
        end
      end
    end
  end

  return return_value;
end
