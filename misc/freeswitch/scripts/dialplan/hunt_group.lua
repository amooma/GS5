-- Gemeinschaft 5 module: hunt group class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

HuntGroup = {}

local DEFAULT_MEMBER_TIMEOUT = 20;

-- Create HuntGroup object
function HuntGroup.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.class = 'huntgroup';
  self.log = arg.log;
  self.database = arg.database;
  self.record = arg.record;
  return object;
end


function HuntGroup.find_by_id(self, id)
  local sql_query = 'SELECT * FROM `hunt_groups` WHERE `id`= '.. tonumber(id) .. ' LIMIT 1';
  local hunt_group = nil;

  self.database:query(sql_query, function(entry)
    hunt_group = HuntGroup:new(self);
    hunt_group.record = entry;
    hunt_group.id = tonumber(entry.id);
    hunt_group.uuid = entry.uuid;
  end)

  return hunt_group;
end


function HuntGroup.find_by_uuid(self, uuid)
  local sql_query = 'SELECT * FROM `hunt_groups` WHERE `id`= "'.. uuid .. '" LIMIT 1';
  local hunt_group = nil;

  self.database:query(sql_query, function(entry)
    hunt_group = HuntGroup:new(self);
    hunt_group.record = entry;
    hunt_group.id = tonumber(entry.id);
    hunt_group.uuid = entry.uuid;
  end)

  return hunt_group;
end


function HuntGroup.list_active_members(self)
  local sql_query = 'SELECT `a`.`number`, `b`.`name` \
    FROM `phone_numbers` `a` \
    LEFT JOIN `hunt_group_members` `b` ON `a`.`phone_numberable_type` = "huntgroupmember" AND `a`.`phone_numberable_id` = `b`.`id` \
    WHERE `a`.`phone_numberable_type` = "huntgroupmember" \
    AND `b`.`active` IS TRUE \
    AND `b`.`hunt_group_id` = ' .. self.record.id;

  local hunt_group_members = {}

  self.database:query(sql_query, function(hunt_group_members_entry)
    table.insert(hunt_group_members, hunt_group_members_entry);
  end)

  return hunt_group_members;
end


function HuntGroup.is_member_by_numbers(self, numbers)
  local sql_query = 'SELECT `a`.`number`, `b`.`name` \
    FROM `phone_numbers` `a` \
    LEFT JOIN `hunt_group_members` `b` ON `a`.`phone_numberable_type` = "huntgroupmember" AND `a`.`phone_numberable_id` = `b`.`id` \
    WHERE `a`.`phone_numberable_type` = "huntgroupmember" \
    AND `b`.`active` IS TRUE \
    AND `b`.`hunt_group_id` = ' .. self.record.id .. '\
    AND `a`.`number` IN ("' .. table.concat( numbers, '","') .. '") LIMIT 1';

  local hunt_group_member = false;

  self.database:query(sql_query, function(hunt_group_members_entry)
    hunt_group_member = true;
  end)

  return hunt_group_member;
end


function HuntGroup.run(self, dialplan_object, caller, destination)
  local hunt_group_members = self:list_active_members();

  if #hunt_group_members == 0 then
    return { disposition = 'HUNT_GROUP_EMPTY', code = 480, phrase = 'No active users' }
  end

  self.log:info('HUNTGROUP ', self.record.id, ' - name: ', self.record.name, ', strategy: ', self.record.strategy,', members: ', #hunt_group_members);

  local save_destination = caller.destination;

  local destinations = {}
  for index, hunt_group_member in ipairs(hunt_group_members) do
    local destination = dialplan_object:destination_new{ number = hunt_group_member.number };
    if destination.type == 'unknown' then
      self.log:notice('HG_DESTINATION - number: ', destination.number, ', hunt_group_member.number: ', hunt_group_member.number);

      
      caller.destination_number = destination.number;

      require 'dialplan.router'
      local route =  dialplan.router.Router:new{ log = self.log, database = self.database, caller = caller, variables = caller }:route_run('outbound', true);

      if route then
        destination = dialplan_object:destination_new{ ['type'] = route.type, id = route.id, number = route.destination_number }

        local ignore_keys = {
          id = true,
          ['type'] = true,
          channel_variables = true,
        };

        for key, value in pairs(route) do
          if not ignore_keys[key] then
            destination[key] = value;
          end
        end

        table.insert(destinations, destination);
      end
    else
      table.insert(destinations, destination);
    end
  end

  caller.destination = save_destination;
  caller.destination_number = save_destination.number;

  local forwarding_destination = nil;
  if caller.forwarding_service == 'assistant' and caller.auth_account then
    forwarding_destination = dialplan_object:destination_new{ type = caller.auth_account.class, id = caller.auth_account.id, number = forwarding_number }
    forwarding_destination.alert_info = 'http://amooma.com;info=Ringer0;x-line-id=0';
  end

  local result = { continue = false };
  local start_time = os.time();
  if self.record.strategy == 'ring_recursively' then
    local member_timeout = tonumber(self.record.seconds_between_jumps) or DEFAULT_MEMBER_TIMEOUT;
    local run_queue = true;
    while run_queue do
      for index, member_destination in ipairs(destinations) do
        local recursive_destinations = { member_destination }
        if forwarding_destination then
          table.insert(recursive_destinations, forwarding_destination);
        end
        require 'dialplan.sip_call'
        result = dialplan.sip_call.SipCall:new{ log = self.log, database = self.database, caller = caller }:fork( recursive_destinations, { callee_id_number = destination.number, timeout = member_timeout });
        if result.disposition == 'SUCCESS' then
          if result.fork_index then
            result.destination = recursive_destinations[result.fork_index];
          end
          run_queue = false;
          break;
        elseif os.time() > start_time + dialplan_object.dial_timeout_active then
          run_queue = false;
          break;
        elseif not caller:ready() then
          run_queue = false;
          break;
        end
      end
      if tostring(result.code) == '486' then
        self.log:info('HUNTGROUP ', self.record.id, ' - all members busy');
        run_queue = false;
      end
    end
  else
    if forwarding_destination then
      table.insert(destinations, forwarding_destination);
    end

    require 'dialplan.sip_call'
    result = dialplan.sip_call.SipCall:new{ log = self.log, database = self.database, caller = caller }:fork( destinations, 
      { 
        callee_id_number = destination.number, 
        timeout = dialplan_object.dial_timeout_active, 
        send_ringing = ( dialplan_object.send_ringing_to_gateways and caller.from_gateway ),
      });
    if result.fork_index then
      result.destination = destinations[result.fork_index];
    end

    return result; 
  end

  return result;
end


function HuntGroup.list_destination_numbers(self)
  require "common.phone_number"
  local phone_number_class = common.phone_number.PhoneNumber:new(defaults)

  local sql_query = string.format("SELECT * FROM `phone_numbers` WHERE `state`='active' AND `phone_numberable_type` = 'HuntGroupMember' AND `phone_numberable_id` IN ( \
    SELECT `id` FROM `hunt_group_members` WHERE `active` IS TRUE AND `hunt_group_id`=%d ) ORDER BY `position` ASC", tonumber(self.record.id));
  local phone_numbers = {}

  self.database:query(sql_query, function(hunt_group_number_entry)
    local number_object = phone_number_class:find_by_number(hunt_group_number_entry.number)
    if number_object and number_object.record then
      table.insert(phone_numbers, {number = hunt_group_number_entry.number, destination_type = number_object.record.phone_numberable_type, destination_id = number_object.record.phone_numberable_id});
    else
      table.insert(phone_numbers, {number = hunt_group_number_entry.number});
    end
  end)

  return phone_numbers ;
end
