-- Gemeinschaft 5 module: FS api class
-- (c) AMOOMA GmbH 2012
-- 

module(...,package.seeall)

FApi = {}

-- create fapi object
function FApi.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.class = 'fapi';
  self.log = arg.log;
  self.uuid = arg.uuid;
  self.fs_api = freeswitch.API();
  return object;
end


function FApi.return_result(self, result, positive, negative, unspecified)
  if not result then
    return negative;
  end
  result = tostring(result);

  if result:match('^-ERR') then
    return negative;
  elseif result:match('^_undef_') then
    return negative;
  elseif result:match('^+OK') then
    return positive;
  else
    return unspecified;
  end
end


function FApi.sleep(self, value)
  freeswitch.msleep(value);
end


function FApi.channel_exists(self, uuid)
  require 'common.str'
  uuid = uuid or self.uuid;
  return common.str.to_b(freeswitch.API():execute('uuid_exists', tostring(uuid)));
end


function FApi.get_variable(self, variable_name)
  local result = freeswitch.API():execute('uuid_getvar', tostring(self.uuid) .. ' ' .. tostring(variable_name));
  return self:return_result(result, result, nil, result);
end


function FApi.set_variable(self, variable_name, value)
  value = value or '';
  
  local result = freeswitch.API():execute('uuid_setvar', tostring(self.uuid) .. ' ' .. tostring(variable_name) .. ' ' .. tostring(value));
  return self:return_result(result, true);
end


function FApi.continue(self)
  local result = freeswitch.API():execute('break', tostring(self.uuid));
  return self:return_result(result, true, false);
end

function FApi.create_uuid(self, uuid)
  local result = self.fs_api:execute('create_uuid', uuid);
  return result;
end

function FApi.execute(self, function_name, function_parameters)
  local result = self.fs_api:execute(function_name, function_parameters);
  return self:return_result(result, true);
end
