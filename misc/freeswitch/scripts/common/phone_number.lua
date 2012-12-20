-- Gemeinschaft 5 module: phone number class
-- (c) AMOOMA GmbH 2012
-- 

module(...,package.seeall)

PhoneNumber = {}

PHONE_NUMBER_INTERNAL_TYPES =  { 'SipAccount', 'Conference', 'FaxAccount', 'Callthrough', 'HuntGroup', 'AutomaticCallDistributor' }

-- create phone number object
function PhoneNumber.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.class = 'phonenumber';
  self.log = arg.log;
  self.database = arg.database;
  self.record = arg.record;
  self.domain = arg.domain;
  self.DEFAULT_CALL_FORWARDING_DEPTH = 20;
  return object;
end

-- find phone number by id
function PhoneNumber.find_by_id(self, id)
  local sql_query = 'SELECT * FROM `phone_numbers` WHERE `id`= ' .. tonumber(id) .. ' LIMIT 1';
  
  local phone_number = nil;

  self.database:query(sql_query, function(number_entry)
    phone_number = PhoneNumber:new(self);
    phone_number.record = number_entry;
    phone_number.id = tonumber(number_entry.id);
    phone_number.uuid = number_entry.uuid;
  end)

  return phone_number;
end

-- find phone number by number
function PhoneNumber.find_by_number(self, number, phone_numberable_types)
  require 'common.str'

  phone_numberable_types = phone_numberable_types or PHONE_NUMBER_INTERNAL_TYPES

  local sql_query = 'SELECT * FROM `phone_numbers` \
    WHERE `number`= ' .. common.str.to_sql(number) .. ' \
    AND `phone_numberable_type` IN ("' .. table.concat(phone_numberable_types, '","') .. '") \
    AND `state` = "active" LIMIT 1';

  local phone_number = nil;

  self.database:query(sql_query, function(number_entry)
    phone_number = PhoneNumber:new(self);
    phone_number.record = number_entry;
  end)

  return phone_number;
end

-- Find numbers by owner id and type
function PhoneNumber.find_all_by_owner(self, owner_id, owner_type)
  local sql_query = 'SELECT * FROM `phone_numbers` WHERE `phone_numberable_type`="' .. owner_type .. '" AND `phone_numberable_id`= ' .. tonumber(owner_id) ..' ORDER BY `position`';
  local phone_numbers = {}

  self.database:query(sql_query, function(number_entry)
    phone_numbers[tonumber(number_entry.id)] = PhoneNumber:new(self);
    phone_numbers[tonumber(number_entry.id)].record = number_entry;
  end)

  return phone_numbers;
end

-- List numbers by owner id and type
function PhoneNumber.list_by_owner(self, owner_id, owner_type)
  local sql_query = 'SELECT * FROM `phone_numbers` WHERE `phone_numberable_type`="' .. owner_type .. '" AND `phone_numberable_id`= ' .. tonumber(owner_id) ..' ORDER BY `position`';
  local phone_numbers = {}

  self.database:query(sql_query, function(number_entry)
    table.insert(phone_numbers, number_entry.number)
  end)

  return phone_numbers;
end

-- List numbers by same owner
function PhoneNumber.list_by_same_owner(self, number, owner_types)
  local phone_number = self:find_by_number(number, owner_types)
  
  if phone_number then
    return self:list_by_owner(phone_number.record.phone_numberable_id, phone_number.record.phone_numberable_type);
  end
end

-- Retrieve call forwarding
function PhoneNumber.call_forwarding(self, caller_ids)
  require 'common.str'

  sources = sources or {};
  table.insert(sources, '');

  local sql_query = 'SELECT \
    `a`.`destination` AS `number`, \
    `a`.`call_forwardable_id` AS `id`, \
    `a`.`call_forwardable_type` AS `type`, \
    `a`.`timeout`, `a`.`depth`, \
    `a`.`source`, \
    `b`.`value` AS `service` \
    FROM `call_forwards` `a` JOIN `call_forward_cases` `b` ON `a`.`call_forward_case_id` = `b`.`id` \
    WHERE `a`.`phone_number_id`= ' .. tonumber(self.record.id) .. ' \
    AND `a`.`active` IS TRUE';

  local call_forwarding = {}

  self.database:query(sql_query, function(forwarding_entry)
    local entry_match = false;

    if common.str.blank(forwarding_entry.source) then
      entry_match = true;
    else
      local sources = common.str.strip_to_a(forwarding_entry.source, ',')
      for index, source in ipairs(sources) do
        for index, caller_id in ipairs(caller_ids) do
          if caller_id:match(source) then
            entry_match = true;
            self.log:debug('CALL_FORWARDING_GET - source match: ', source, ' ~ ', caller_id );
            break;
          end
        end
      end
    end

    if entry_match then
      call_forwarding[forwarding_entry.service] = forwarding_entry;
      self.log:debug('CALL_FORWARDING_GET - PhoneNumber=', self.record.id, '/', self.record.uuid, '@', self.record.gs_node_id, 
        ', number: ', self.record.number, 
        ', service: ', forwarding_entry.service, 
        ', destination: ',forwarding_entry.type, '=', forwarding_entry.id, 
        ', number: ', forwarding_entry.number);
    end
  end)

  return call_forwarding;
end


function PhoneNumber.call_forwarding_effective(self, service, source)
  local conditions = {}
  table.insert(conditions, '`phone_number_id` = ' .. self.record.id);

  if source then
    table.insert(conditions, '`source` = "' .. source);
  else
    table.insert(conditions, '(`source` = "" OR `source` IS NULL)');
  end

  if service then
    table.insert(conditions, '`call_forward_case_id` IN (SELECT `id` FROM `call_forward_cases` WHERE `value` = "' .. service .. '")');
  end

  -- get call forwarding entry
  local sql_query = 'SELECT `destination`,`active`,`timeout`,`call_forwardable_type`, `call_forwardable_id` FROM `call_forwards` WHERE ' .. table.concat(conditions, ' AND ') .. '  ORDER BY `active` DESC LIMIT 1';
  local call_forwarding = nil;

  self.database:query(sql_query, function(entry)
    call_forwarding = entry;
  end)

  return call_forwarding;
end


function PhoneNumber.call_forwarding_off(self, service, source, delete)
  local conditions = {}
  table.insert(conditions, '`phone_number_id` = ' .. self.record.id);

  if source then
    table.insert(conditions, '`source` = "' .. source);
  else
    table.insert(conditions, '(`source` = "" OR `source` IS NULL)');
  end

  if service then
    table.insert(conditions, '`call_forward_case_id` IN (SELECT `id` FROM `call_forward_cases` WHERE `value` = "' .. service .. '")');
  end

  self.log:info('PHONE_NUMBER_CALL_FORWARDING_OFF - service: ', service, ', number: ', self.record.number);

  local call_forwarding_ids = {}

  local sql_query = 'SELECT `id` FROM `call_forwards` WHERE ' .. table.concat(conditions, ' AND ');
  self.database:query(sql_query, function(record)
    table.insert(call_forwarding_ids, record.id);
  end)

  require 'common.call_forwarding'
  local call_forwarding_class = common.call_forwarding.CallForwarding:new{ log = self.log, database = self.database, domain = self.domain };
  
  for index, call_forwarding_id in ipairs(call_forwarding_ids) do
    if tonumber(call_forwarding_id) then
      local call_forwarding = call_forwarding_class:find_by_id(call_forwarding_id);
      call_forwarding:presence_set('terminated'); 
    end
  end

  -- set call forwarding entry inactive
  local sql_query = 'UPDATE `call_forwards` SET `active` = FALSE, `updated_at` = NOW() WHERE ' .. table.concat(conditions, ' AND ');

  local call_forwards = {};

  -- or delete call forwarding entry
  if delete then
    sql_query = 'SELECT * FROM `call_forwards` WHERE ' .. table.concat(conditions, ' AND ');
    self.database:query(sql_query, function(forwarding_entry)
      table.insert(call_forwards, forwarding_entry)
    end)
    sql_query = 'DELETE FROM `call_forwards` WHERE ' .. table.concat(conditions, ' AND ');
  end

  if not self.database:query(sql_query) then
    self.log:notice('PHONE_NUMBER_CALL_FORWARDING_OFF - call forwarding could not be deactivated - number: ', self.record.number);
    return false;
  end

  if delete then
    require 'common.sync_log'
    local sync_log_class = common.sync_log.SyncLog:new{ log = self.log, database = self.database, homebase_ip_address = '' }

    for index, call_forward in ipairs(call_forwards) do
      sync_log_class:insert('CallForward', call_forward, 'destroy', nil);
    end
  end

  return true;
end


function PhoneNumber.call_forwarding_on(self, service, destination, destination_type, timeout, source)
  require 'common.str'
  if call_forwarding_service == 'noanswer' then
    timeout = tonumber(timeout) or '30';
  else
    timeout = 'NULL';
  end

  if source then
    sql_query = 'SELECT `id`, `destination`, `call_forwardable_type`, `call_forward_case_id` FROM `call_forwards` \
      WHERE `phone_number_id` = ' .. self.record.id .. ' \
      AND `call_forward_case_id` IN (SELECT `id` FROM `call_forward_cases` WHERE `value` = "' .. service .. '") \
      AND `source` = "' .. source .. '" AND `phone_number_id` = ' .. self.record.id .. ' ORDER BY `active` DESC LIMIT 1';
  else
    sql_query = 'SELECT `id`, `destination`, `call_forwardable_type`, `call_forward_case_id` FROM `call_forwards` \
      WHERE `phone_number_id` = ' .. self.record.id .. ' \
      AND `call_forward_case_id` IN (SELECT `id` FROM `call_forward_cases` WHERE `value` = "' .. service .. '") \
      AND (`source` = "" OR `source` IS NULL) AND `phone_number_id` = ' .. self.record.id .. ' ORDER BY `active` DESC LIMIT 1';
  end

  destination_type = destination_type or '';
  destination = destination or '';
  local service_id = nil;
  local entry_id = 'NULL';

  self.database:query(sql_query, function(record)
    entry_id = record.id;
    service_id = record.call_forward_case_id;
    if common.str.blank(destination) then
      if not common.str.blank(record.call_forwardable_type) then
        destination_type = common.str.downcase(record.call_forwardable_type);
      end
      if not common.str.blank(record.destination) then
        destination = record.destination;
      end
    end
  end)

  if destination == '' and destination_type:lower() ~= 'voicemail' then
    self.log:notice('PHONE_NUMBER_CALL_FORWARDING_ON - destination not specified - destination: ', destination, ', type: ', destination_type,', number: ' .. self.record.number);
    return false;
  end

  if destination_type == '' then
    destination_type = 'PhoneNumber';
  end

  self.log:info('PHONE_NUMBER_CALL_FORWARDING_ON - service: ', service, ', number: ', self.record.number, ', destination: ', destination, ', type: ', destination_type, ', timeout: ', timeout);

  if not service_id then
    sql_query = 'SELECT `id` FROM `call_forward_cases` WHERE `value` = "' .. service .. '"';
    self.database:query(sql_query, function(record)
      service_id = tonumber(record.id);
    end);
  end

  sql_query = 'REPLACE INTO `call_forwards` \
    (`active`, `uuid`, `depth`, `updated_at`, `id`, `phone_number_id`, `call_forward_case_id`, `destination`, `call_forwardable_type`, `timeout`) \
    VALUES \
    (TRUE, UUID(), ' .. self.DEFAULT_CALL_FORWARDING_DEPTH .. ', NOW(), ' .. entry_id .. ', ' .. self.record.id .. ', ' .. service_id .. ', "' .. destination .. '", "'  .. destination_type .. '", '  .. timeout .. ')'

  if not self.database:query(sql_query) then
    self.log:error('PHONE_NUMBER_CALL_FORWARDING_ON - could not be activated - destination: ', destination, ', type: ', destination_type,', number: ' .. self.record.number);
    return false;
  end

  require 'common.call_forwarding'
  local call_forwarding_class = common.call_forwarding.CallForwarding:new{ log = self.log, database = self.database, domain = self.domain };
  if tonumber(entry_id) then
    local call_forwarding = call_forwarding_class:find_by_id(entry_id);
  end

  if call_forwarding then
    if destination_type:lower() == 'voicemail' then
      call_forwarding:presence_set('early');
    else
      call_forwarding:presence_set('confirmed');
    end
  end

  return true;
end


function PhoneNumber.call_forwarding_toggle(self, service, source)
  local call_forwarding = self:call_forwarding_effective(service, source);

  -- no call_forwarding entry: all forwarding is deactivated
  if not call_forwarding then
    return false;
  end

  if tostring(call_forwarding.active) == '1' then
    if self:call_forwarding_off(service, source) then
      return {destination = call_forwarding.destination, destination_type = call_forwarding.destination_type, active = false};
    end
  end

  if self:call_forwarding_on(service, call_forwarding.destination, call_forwarding.destination_type, call_forwarding.timeout, source) then
    return {destination = call_forwarding.destination, destination_type = call_forwarding.destination_type, active = true};
  end

  return nil;
end


function PhoneNumber.call_forwarding_presence_set(self, presence_state, service)
  service = service or 'always';
  local dialplan_function = 'f-cfutg';

  if service == 'assistant' then
    dialplan_function = 'f-cfatg';
  end

  require "dialplan.presence"
  local presence = dialplan.presence.Presence:new();

  presence:init{log = self.log, accounts = { dialplan_function .. '-' .. tostring(self.record.id) }, domain = self.domain, uuid = 'call_forwarding_number_' ..  tostring(self.record.id)};

  return presence:set(presence_state);
end


-- Retrieve ringtone
function PhoneNumber.ringtone(self, id)
  id = id or self.record.id;
  if not id then
    return false;
  end

  local sql_query = "SELECT * FROM `ringtones` WHERE `ringtoneable_type` = \"PhoneNumber\" AND `ringtoneable_id`=" .. self.record.id .. " LIMIT 1";
  local ringtone = nil;

  self.database:query(sql_query, function(entry)
    ringtone = entry;
  end)

  return ringtone;
end
