-- Gemeinschaft 5 module: call forwarding class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

CallForwarding = {}

-- Create CallForwarding object
function CallForwarding.new(self, arg, object)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self
  self.log = arg.log;
  self.database = arg.database;
  self.record = arg.record;
  self.domain = arg.domain;
  self.parent = arg.parent;
  return object;
end

-- Find call forwarding by id
function CallForwarding.find_by_id(self, id)
  local sql_query = 'SELECT * FROM `call_forwards` WHERE `id`= ' .. tonumber(id) .. ' LIMIT 1';
  local record = nil

  self.database:query(sql_query, function(entry)
    record = entry;
  end)

  if record then
    call_forwarding = CallForwarding:new(self)
    call_forwarding.record = record
    return call_forwarding
  end

  return nil
end


function CallForwarding.list_by_owner(self, call_forwardable_id, call_forwardable_type, caller_ids)
  require 'common.str';

  if not tonumber(call_forwardable_id) or common.str.blank(call_forwardable_type) then
    return {};
  end

  local sql_query = 'SELECT \
    `a`.`destination` AS `number`, \
    `a`.`destinationable_id` AS `id`, \
    `a`.`destinationable_type` AS `type`, \
    `a`.`call_forwardable_id`, \
    `a`.`call_forwardable_type`, \
    `a`.`timeout`, `a`.`depth`, \
    `a`.`source`, \
    `b`.`value` AS `service` \
    FROM `call_forwards` `a` JOIN `call_forward_cases` `b` ON `a`.`call_forward_case_id` = `b`.`id` \
    WHERE `a`.`call_forwardable_id`= ' .. tonumber(call_forwardable_id) .. ' \
    AND `a`.`call_forwardable_type`= ' .. self.database:escape(call_forwardable_type, '"') .. ' \
    AND `a`.`active` IS TRUE';

  local call_forwarding_entries = {};

  self.database:query(sql_query, function(forwarding_entry)
    local entry_match = false;

    if common.str.blank(forwarding_entry.source) then
      entry_match = true;
    else
      local sources = common.str.strip_to_a(forwarding_entry.source, ',')
      for source_index=1, #sources do
        for caller_id_index=1, #caller_ids do
          if caller_ids[caller_id_index]:match(sources[source_index]) then
            entry_match = true;
            self.log:debug('CALL_FORWARDING - source match: ', sources[source_index], ' ~ ', caller_ids[caller_id_index] );
            break;
          end
        end
      end
    end

    if entry_match then
      call_forwarding_entries[forwarding_entry.service] = forwarding_entry;
      self.log:debug('CALL_FORWARDING - ', call_forwardable_type, '=', call_forwardable_id,
        ', service: ', forwarding_entry.service, 
        ', destination: ',forwarding_entry.type, '=', forwarding_entry.id, 
        ', number: ', forwarding_entry.number);
    end
  end)

  return call_forwarding_entries;
end


function CallForwarding.presence_set(self, presence_state, id)
  id = id or self.record.id;

  if not id or not presence_state then
    return;
  end

  require 'dialplan.presence'
  local presence = dialplan.presence.Presence:new();

  presence:init{log = self.log, accounts = { 'f-cftg-' .. id }, domain = self.domain, uuid = 'call_forwarding_' .. id};

  return presence:set(presence_state);
end


function CallForwarding.service_id_by_name(self, service_name)
  local service_id = nil;
    sql_query = 'SELECT `id` FROM `call_forward_cases` WHERE `value` = ' .. self.database:escape(service_name, '"');
    self.database:query(sql_query, function(record)
      service_id = tonumber(record.id);
    end);

  return service_id;
end


function CallForwarding.camelize_type(self, account_type)
  ACCOUNT_TYPES = {
    sipaccount = 'SipAccount',
    conference = 'Conference',
    faxaccount = 'FaxAccount',
    callthrough = 'Callthrough',
    huntgroup = 'HuntGroup',
    automaticcalldistributor = 'AutomaticCallDistributor',
  }

  return ACCOUNT_TYPES[account_type] or account_type;
end

function CallForwarding.call_forwarding_on(self, service, destination, destination_type, timeout, source)
  require 'common.str'

  if source then
    sql_query = 'SELECT `id`, `destination`, `destinationable_type`, `destinationable_id`, `call_forward_case_id`, `position`, `timeout` FROM `call_forwards` \
      WHERE `call_forwardable_id` = ' .. self.parent.id .. ' \
      AND `call_forwardable_type` = "' .. self.parent.class .. '" \
      AND `call_forward_case_id` IN (SELECT `id` FROM `call_forward_cases` WHERE `value` = "' .. service .. '") \
      AND `source` = "' .. source .. '" ORDER BY `active` DESC LIMIT 1';
  else
    sql_query = 'SELECT `id`, `destination`, `destinationable_type`, `destinationable_id`, `call_forward_case_id`, `position`, `timeout` FROM `call_forwards` \
      WHERE `call_forwardable_id` = ' .. self.parent.id .. ' \
      AND `call_forwardable_type` = "' .. self.parent.class .. '" \
      AND `call_forward_case_id` IN (SELECT `id` FROM `call_forward_cases` WHERE `value` = "' .. service .. '") \
      AND (`source` = "" OR `source` IS NULL) ORDER BY `active` DESC LIMIT 1';
  end

  destination_type = destination_type or 'PhoneNumber';
  local destination_id = nil;
  destination = destination or '';
  local service_id = nil;
  local entry_id = nil;

  self.database:query(sql_query, function(record)
    entry_id = tonumber(record.id);
    service_id = record.call_forward_case_id;
    timeout = tonumber(timeout) or tonumber(record.timeout);
    if common.str.blank(destination) then
      if not common.str.blank(record.destinationable_type) then
        destination_type = common.str.downcase(record.destinationable_type);
      end
      if not common.str.blank(record.destination) then
        destination = record.destination;
      end
      destination_id = tonumber(record.destinationable_id);
    end
  end)

  if service == 'noanswer' then
    timeout = tonumber(timeout) or '30';
  else
    timeout = nil;
  end

  if destination == '' and not estination_id and destination_type:lower() ~= 'voicemail' then
    self.log:notice('CALL_FORWARDING_ON ', service, ' - for: ', self.parent.class, '=', self.parent.id, '/', self.parent.uuid,' - destination not specified: ', destination_type, '=', destination_id);
    return false;
  end

  if not tonumber(service_id) then
    service_id = self:service_id_by_name(service);
  end

  local call_forwarding_record = {
    id = entry_id,
    active = true,
    uuid = { 'UUID()', raw = true },
    updated_at = { 'NOW()', raw = true },
    created_at = { 'NOW()', raw = true },
    call_forwardable_id = self.parent.id,
    call_forwardable_type = self:camelize_type(self.parent.class),
    call_forward_case_id = service_id,
    destination = destination,
    destinationable_type = self:camelize_type(destination_type),
    destinationable_id = destination_id,
    timeout = timeout,
    position = 1,
  };

  local result = self.database:insert_or_update('call_forwards', call_forwarding_record, { created_at = false, position = false });

  if not result then
    self.log:notice('CALL_FORWARDING_ON ', service, ' - could not be activated for: ', self.parent.class, '=', self.parent.id, '/', self.parent.uuid,' - destination: ', destination_type, '=', destination_id, '|', destination);
    return false;
  end

  entry_id = entry_id or self.database:last_insert_id();

  self.log:info('CALL_FORWARDING_ON ', service, ' - callforwarding=', entry_id, ', for: ', self.parent.class, '=', self.parent.id, '/', self.parent.uuid, ', destination: ', destination_type, '=', destination_id, '|', destination, ', timeout: ', timeout);

  if tonumber(entry_id) then
    if destination_type:lower() == 'voicemail' then
      self:presence_set('early', entry_id);
    else
      self:presence_set('confirmed', entry_id);
    end
  end

  return result;
end


function CallForwarding.call_forwarding_off(self, service, source, delete)
  local conditions = {}
  table.insert(conditions, '`call_forwardable_id` = ' .. self.parent.id);
  table.insert(conditions, '`call_forwardable_type` = "' .. self.parent.class .. '"');

  if source then
    table.insert(conditions, '`source` = "' .. source);
  else
    table.insert(conditions, '(`source` = "" OR `source` IS NULL)');
  end

  if service then
    table.insert(conditions, '`call_forward_case_id` IN (SELECT `id` FROM `call_forward_cases` WHERE `value` = "' .. service .. '")');
  end

  local call_forwarding_ids = {}
  local sql_query = 'SELECT `id` FROM `call_forwards` WHERE ' .. table.concat(conditions, ' AND ');
  self.database:query(sql_query, function(record)
    table.insert(call_forwarding_ids, record.id);
  end)

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
    self.log:notice('CALL_FORWARDING_OFF ', (service or 'any'), ' - could not be deactivated for: ', self.parent.class, '=', self.parent.id, '/', self.parent.uuid);
    return false;
  end

  if delete then
    require 'common.sync_log'
    local sync_log_class = common.sync_log.SyncLog:new{ log = self.log, database = self.database, homebase_ip_address = '' }

    for index, call_forward in ipairs(call_forwards) do
      sync_log_class:insert('CallForward', call_forward, 'destroy', nil);
    end
  end
  
  for index, entry_id in ipairs(call_forwarding_ids) do
    if tonumber(entry_id) then
      self:presence_set('terminated', entry_id);
    end
  end

  return true;
end
