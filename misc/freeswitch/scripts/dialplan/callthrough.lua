-- CommonModule: Callthrough
--
module(...,package.seeall)

Callthrough = {}

-- Create Callthrough object
function Callthrough.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self)
  self.__index = self
  self.log = arg.log
  self.database = arg.database
  self.record = arg.record
  self.access_authorizations = arg.access_authorizations
  return object
end

-- Find Callthrough by ID
function Callthrough.find_by_id(self, id)
  local sql_query = string.format("SELECT * FROM `callthroughs` WHERE `id`=%d LIMIT 1", id)
  local record = nil

  self.database:query(sql_query, function(callthrough_entry)
    record = callthrough_entry
  end)

  if record then
    local callthrough = Callthrough:new(self);
    callthrough.record = record

    require 'dialplan.access_authorizations'
    callthrough.access_authorizations = dialplan.access_authorizations.AccessAuthorization:new{ log = self.log, database = self.database }:list_by_owner(record.id, 'Callthrough');
    return callthrough
  end

  return nil 
end

function Callthrough.authenticate(self, caller)
  local authorizations = {}
  local logins = {}
  local pins = {}

  caller:answer();
  caller:sleep(1000);

  if not self.access_authorizations or table.getn(self.access_authorizations) == 0 then
    self.log:debug('CALLTHROUGH_AUTHENTICATE - authorization disabled');
    return true;
  end

  self.log:debug('CALLTHROUGH_AUTHENTICATE - access_authorizations: ', #self.access_authorizations);
  for index, authorization in ipairs(self.access_authorizations) do
    if not common.str.blank(authorization.phone_number) then
      if authorization.phone_number == caller.caller_phone_number then
        if authorization.pin and authorization.pin ~= "" then
          if caller.session:read(authorization.pin:len(), authorization.pin:len(), "ivr/ivr-please_enter_pin_followed_by_pound.wav", 3000, "#") ~= authorization.pin then
            self.log:debug("CALLTHROUGH_AUTHENTICATE - Wrong PIN");
            return false;
          else
            self.log:debug("CALLTHROUGH_AUTHENTICATE - Caller was authenticated by caller id: " .. caller.caller_phone_number .. " and PIN");
            return authorization;
          end
        end
        self.log:debug("CALLTHROUGH_AUTHENTICATE - Caller was authenticated by caller id: " .. caller.caller_phone_number);
        return authorization;
      end
    else
      self.log:debug('CALLTHROUGH_AUTHENTICATE - access_authorization=', authorization.id);
      if authorization.id then
        authorizations[authorization.id] = authorization;
        if authorization.login and authorization.login ~= "" then
          logins[authorization.login] = authorization;
        elseif authorization.pin and authorization.pin ~= "" then
          pins[authorization.pin] = authorization;
        end
      end
    end
  end

  local login = nil;
  local pin = nil;


  if next(logins) ~= nil then

    caller.session:streamFile('ivr/ivr-please_enter_the.wav');
    caller.session:streamFile('ivr/ivr-id_number.wav');
    login = caller.session:read(2, 10, 'ivr/ivr-followed_by_pound.wav', 3000, '#');
  end

  if login and logins[tostring(login)] then
    if not logins[tostring(login)].pin or logins[tostring(login)].pin == '' then
      self.log:debug("CALLTHROUGH_AUTHENTICATE - Caller was authenticated by login: " .. login .. " without PIN");
      return logins[tostring(login)];
    end
    pin = caller.session:read(2, 10, "ivr/ivr-please_enter_pin_followed_by_pound.wav", 3000, "#");
    if logins[tostring(login)].pin == pin then
      self.log:debug("CALLTHROUGH_AUTHENTICATE - Caller was authenticated by login: " .. login .. " and PIN");
      return logins[tostring(login)];
    else
      self.log:debug("CALLTHROUGH_AUTHENTICATE - Wrong PIN");
      return false
    end
  end

  if next(pins) ~= nil then
    pin = caller.session:read(2, 10, "ivr/ivr-please_enter_pin_followed_by_pound.wav", 3000, "#");
  end

  self.log:debug("CALLTHROUGH_AUTHENTICATE - No such login, try PIN");

  if pin and pins[tostring(pin)] then
    self.log:debug("CALLTHROUGH_AUTHENTICATE - Caller was authenticated by PIN");
    return pins[tostring(pin)];
  end
  
  self.log:debug("CALLTHROUGH_AUTHENTICATE - No login, wrong PIN - giving up");

  return false;
end

function Callthrough.whitelist(self, number)
  local sql_query = 'SELECT `id` FROM `whitelists` WHERE `whitelistable_type` = "Callthrough" AND `whitelistable_id` = ' .. self.record.id;
  local whitelist_ids = {}

  self.database:query(sql_query, function(entry)
    table.insert(whitelist_ids, entry.id);
  end)

  if next(whitelist_ids) == nil then
    return true;
  end

  -- OPTIMIZE Make sure number contains only valid characters
  local sql_query = 'SELECT `id` FROM `phone_numbers` WHERE \
    `number` = "' .. number .. '" AND \
    `phone_numberable_type` = "Whitelist" AND `phone_numberable_id` IN (' .. table.concat(whitelist_ids, ',') .. ') LIMIT 1';

  local authorized = false
  self.database:query(sql_query, function(entry)
    authorized = true
  end)

  return authorized;
end
