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


function CallForwarding.presence_set(self, presence_state)
  require 'dialplan.presence'
  local presence = dialplan.presence.Presence:new();

  presence:init{log = self.log, accounts = { 'f-cftg-' .. tostring(self.record.id) }, domain = self.domain, uuid = 'call_forwarding_' ..  tostring(self.record.id)};

  return presence:set(presence_state);
end
