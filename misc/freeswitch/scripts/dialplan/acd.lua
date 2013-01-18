-- Gemeinschaft 5 module: acd class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

AutomaticCallDistributor = {}

local DEFAULT_AGENT_TIMEOUT = 20;
local DEFAULT_TIME_RES = 5;
local DEFAULT_WAIT_TIMEOUT = 360;
local DEFAULT_RETRY_TIME = 2;
local DEFAULT_MUSIC_ON_WAIT = 'tone_stream://%(2000,4000,440.0,480.0);loops=-1';

-- create acd object
function AutomaticCallDistributor.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.class = 'automaticcalldistributor';
  self.log = arg.log;
  self.database = arg.database;
  self.record = arg.record;
  self.acd_caller_id = arg.acd_caller_id;
  self.domain = arg.domain;
  return object;
end


function AutomaticCallDistributor.find_by_sql(self, sql_query)
  local acd = nil;

  require 'common.str'

  self.database:query(sql_query, function(entry)
    acd = AutomaticCallDistributor:new(self);
    acd.record = entry;
    acd.id = tonumber(entry.id);
    acd.uuid = entry.uuid;
    acd.agent_timeout = tonumber(entry.agent_timeout) or DEFAULT_AGENT_TIMEOUT;
    acd.announce_position = tonumber(entry.announce_position);
    acd.announce_call_agents = common.str.to_s(entry.announce_call_agents);
    acd.greeting = common.str.to_s(entry.greeting);
    acd.goodbye = common.str.to_s(entry.goodbye);
    acd.music = common.str.to_s(entry.music);
    acd.strategy = common.str.to_s(entry.strategy);
    acd.join = common.str.to_s(entry.join);
    acd.leave = common.str.to_s(entry.leave);
  end)

  return acd;
end


function AutomaticCallDistributor.find_by_id(self, id)
  local sql_query = 'SELECT * FROM `automatic_call_distributors` WHERE `id`= '.. tonumber(id) .. ' LIMIT 1';
  return self:find_by_sql(sql_query);
end


function AutomaticCallDistributor.find_by_uuid(self, uuid)
  local sql_query = 'SELECT * FROM `automatic_call_distributors` WHERE `uuid`= "'.. tostring(uuid) .. '" LIMIT 1';
  return self:find_by_sql(sql_query);
end


function AutomaticCallDistributor.callers_count(self)
  return self.database:query_return_value('SELECT COUNT(*) FROM `acd_callers` `a` JOIN `channels` `b` ON `a`.`channel_uuid` = `b`.`uuid` WHERE `automatic_call_distributor_id` = ' .. self.id);
end


function AutomaticCallDistributor.caller_new(self, uuid)
  local sql_query = 'INSERT INTO `acd_callers` \
    (`enter_time`, `created_at`, `updated_at`, `status`, `automatic_call_distributor_id`, `channel_uuid`) \
    VALUES (NOW(), NOW(), NOW(), "enter", ' .. self.id .. ', "' .. uuid .. '")';

  if self.database:query(sql_query) then
     self.acd_caller_id = self.database:last_insert_id();
  end
end


function AutomaticCallDistributor.caller_update(self, attributes)
  local attributes_sql = { '`updated_at` = NOW()' };
  for key, value in pairs(attributes) do
    table.insert(attributes_sql, '`' .. key .. '` = "' .. value .. '"');
  end

  local sql_query = 'UPDATE `acd_callers` \
    SET  '.. table.concat(attributes_sql, ',') .. '\
    WHERE `id` = ' .. tonumber(self.acd_caller_id);
  return self.database:query(sql_query);
end


function AutomaticCallDistributor.caller_delete(self, id)
  id = id or self.acd_caller_id;
  local sql_query = 'DELETE FROM `acd_callers` \
    WHERE `id` = ' .. tonumber(id);
  return self.database:query(sql_query);
end


function AutomaticCallDistributor.agent_find_by_acd_and_destination(self, acd_id, destination_type, destination_id)
  local sql_query = 'SELECT * FROM `acd_agents` \
    WHERE `automatic_call_distributor_id` = ' .. acd_id .. ' \
    AND `destination_type` = "' .. destination_type .. '" \
    AND `destination_id` = ' .. destination_id;

  local agent = nil;
  self.database:query(sql_query, function(entry)
    agent = entry;
  end)
  
  return agent;
end


function AutomaticCallDistributor.agent_status_presence_set(self, agent_id, presence_state)
  require "dialplan.presence"
  local presence = dialplan.presence.Presence:new();

  presence:init{log = self.log, accounts = { 'f-acdmtg-' .. tostring(agent_id) }, domain = self.domain, uuid = 'acd_agent_' ..  tostring(agent_id)};
  return presence:set(presence_state);
end


function AutomaticCallDistributor.agent_status_get(self, agent_id)
  local sql_query = 'SELECT `status` FROM `acd_agents` WHERE `id` = ' .. agent_id;
  return self.database:query_return_value(sql_query);
end


function AutomaticCallDistributor.agent_status_toggle(self, agent_id, destination_type, destination_id)
  local sql_query = 'UPDATE `acd_agents` SET `status` = IF(`status` = "active", "inactive", "active") \
    WHERE `id` = ' .. agent_id .. ' \
    AND `destination_type` = "' .. destination_type .. '" \
    AND `destination_id` = ' .. destination_id;
  
  if not self.database:query(sql_query) then
    return nil;
  end

  local status = self:agent_status_get(agent_id);

  if tostring(status) == 'active' then
    self:agent_status_presence_set(agent_id, 'confirmed');
  else
    self:agent_status_presence_set(agent_id, 'terminated');
  end

  return status;
end


function AutomaticCallDistributor.agents_active(self)
  local sql_query = 'SELECT * FROM `acd_agents` \
    WHERE `status` = "active" AND destination_type != "SipAccount" AND `automatic_call_distributor_id` = ' .. tonumber(self.id);
  
  local agents = {}
  self.database:query(sql_query, function(entry)
    table.insert(agents, entry);
  end);

  local sql_query = 'SELECT `a`.*  FROM `acd_agents` `a` \
    JOIN `sip_accounts` `b` ON `a`.`destination_id` = `b`.`id` \
    JOIN `sip_registrations` `c` ON `b`.`auth_name` = `c`.`sip_user` \
    WHERE `a`.`status` = "active" AND `a`.destination_type = "SipAccount" AND `a`.`automatic_call_distributor_id` = ' .. tonumber(self.id);
  
  self.database:query(sql_query, function(entry)
    table.insert(agents, entry);
  end);

  return agents;
end


function AutomaticCallDistributor.agents_available(self, strategy)
  local order_by = '`a`.`id` DESC';

  if strategy then
    if strategy == 'round_robin' then
      order_by = '`a`.`last_call` ASC, `a`.`id` DESC';
    end
  end

  local sql_query = 'SELECT  `a`.`id`, `a`.`name`, `a`.`destination_type`, `a`.`destination_id`, `b`.`auth_name`, `b`.`gs_node_id`, `c`.`callstate` \
    FROM `acd_agents` `a` LEFT JOIN `sip_accounts` `b` ON `a`.`destination_id` = `b`.`id` \
    JOIN `sip_registrations` `d` ON `b`.`auth_name` = `d`.`sip_user` \
    LEFT JOIN `channels` `c` ON `c`.`name` LIKE CONCAT("%", `b`.`auth_name`, "@%") \
    WHERE `a`.`status` = "active"  AND `a`.`destination_id` IS NOT NULL AND `a`.`automatic_call_distributor_id` = ' .. tonumber(self.id) .. ' \
    ORDER BY ' .. order_by;
  
  local accounts = {}
  self.database:query(sql_query, function(entry)
    if not entry.callstate then
      table.insert(accounts, entry);
    end
  end);

  return accounts;
end


function AutomaticCallDistributor.agent_update_call(self, agent_id)

  local sql_query = 'UPDATE `acd_agents` \
    SET `last_call` = NOW(), `calls_answered` = IFNULL(`calls_answered`, 0) + 1 \
    WHERE `id` = ' .. tonumber(agent_id);
  return self.database:query(sql_query);
end


function AutomaticCallDistributor.call_position(self)
  local sql_query = 'SELECT COUNT(*) FROM `acd_callers` `a` JOIN `channels` `b` ON `a`.`channel_uuid` = `b`.`uuid` \
  WHERE `automatic_call_distributor_id` = ' .. tonumber(self.id) .. ' AND `status` = "waiting" AND `id` < ' .. tonumber(self.acd_caller_id);

  return tonumber(self.database:query_return_value(sql_query));
end


function AutomaticCallDistributor.wait_turn(self, caller_uuid, acd_caller_id, timeout, retry_timeout)
  self.acd_caller_id = acd_caller_id or self.acd_caller_id;
  timeout = timeout or DEFAULT_WAIT_TIMEOUT;
  local available_agents = {};
  local active_agents = {};
  local position = self:call_position();

  self.log:info('ACD ', self.id, ' WAIT - timeout: ', timeout, ', res: ', DEFAULT_TIME_RES, ', retry_timeout: ', retry_timeout, ', position: ', position + 1);

  require 'common.fapi'
  local fapi = common.fapi.FApi:new{ log = self.log, uuid = caller_uuid }
  
  local acd_status = nil;
  local start_time = os.time();
  local exit_time = start_time + timeout;

  if tonumber(retry_timeout) then
     self.log:info('ACD ', self.id, ' WAIT - retry_timeout: ', retry_timeout);
    fapi:sleep(retry_timeout * 1000);
  end
  
  while (exit_time > os.time() and fapi:channel_exists()) do
    available_agents = self:agents_available();
    active_agents = self:agents_active();
    local current_position = self:call_position();

    if position ~= current_position then
      position = current_position;
      self.log:info('ACD ', self.id, ' WAIT - agents: ', #available_agents, '/', #active_agents, ', position: ', position + 1, ', wait_time: ', os.time()-start_time);

      if tostring(self.announce_position) >= '0' and position > 0 then
        acd_status = 'announce_position';
        fapi:set_variable('acd_position', position + 1); 
        break;
      end
    else
      self.log:debug('ACD ', self.id, ' WAIT - agents: ', #available_agents, '/', #active_agents, ', position: ', position + 1, ', wait_time: ', os.time()-start_time);
    end
    
    if #available_agents == 0 and self.leave:find('no_agents_available') then
      acd_status = 'no_agents';
      break;
    elseif #active_agents == 0 and self.leave:find('no_agents_active') then
      acd_status = 'no_agents';
      break;
    elseif position == 0 and #available_agents > 0 then
      acd_status = 'call_agents';
      break;
    end

    if tonumber(self.announce_position) and tonumber(self.announce_position) > 0 and tonumber(self.announce_position) <= os.time()-start_time then
      acd_status = 'announce_position';
      fapi:set_variable('acd_position', position + 1); 
      break;
    end

    fapi:sleep(DEFAULT_TIME_RES * 1000);
  end

  if not acd_status then
    if (exit_time <= os.time()) then
      acd_status = 'timeout';
    else
      acd_status = 'unspecified';
    end
  end

  self.log:info('ACD ', self.id, ' WAIT END - status: ', acd_status, ', agents: ', #available_agents, '/', #active_agents, ', position: ', position + 1, ', wait_time: ', os.time()-start_time);

  fapi:set_variable('acd_status', acd_status);
  if tostring(fapi:get_variable('acd_waiting')) == 'true' then
    fapi:continue();
  end
end


function AutomaticCallDistributor.wait_play_music(self, caller, timeout, retry_timeout, music)
  local result = caller:result('luarun(acd_wait.lua ' .. caller.uuid .. ' ' .. tostring(self.id) .. ' ' .. tostring(timeout) .. ' ' .. tostring(retry_timeout) .. ' ' .. self.acd_caller_id .. ')');
  if not tostring(result):match('^+OK') then
    self.log:error('ACD ', self.id,' WAIT_PLAY_MUSIC - error starting acd thread');
    return 'error';
  end

  caller:set_variable('acd_waiting', true);
  caller.session:streamFile(music or DEFAULT_MUSIC_ON_WAIT);
  caller:set_variable('acd_waiting', false);

  local acd_status = caller:to_s('acd_status');
  if acd_status == '' then
    acd_status = 'abandoned';
  end

  return acd_status;
end


function AutomaticCallDistributor.on_answer(self, destination)
  self.log:info('ACD ', self.id, ' ANSWERED - agent: ', destination.type, '=', destination.id, '/', destination.uuid)
  self:caller_update({status = 'answered'});
end


function AutomaticCallDistributor.call_agents(self, dialplan_object, caller, destination)
  local available_agents = self:agents_available(self.strategy);

  self.log:info('ACD ', self.id, ' CALL_AGENTS - strategy: ', self.strategy, ', available_agents: ', #available_agents);

  caller:set_variable('ring_ready', true);
  
  local destinations = {}
  for index, agent in ipairs(available_agents) do
    self.log:info('ACD ', self.id, ' AGENT - name: ', agent.name, ', destination: ', agent.destination_type, '=', agent.destination_id, '@', agent.gs_node_id, ', local_node: ', dialplan_object.node_id);
    table.insert(destinations, dialplan_object:destination_new{ type = agent.destination_type, id = agent.destination_id, node_id = agent.gs_node_id, data = agent.id });
  end

  local result = { continue = false };
  local start_time = os.time();

  require 'dialplan.sip_call'
  if self.strategy == 'ring_all' then
    result = dialplan.sip_call.SipCall:new{ log = self.log, database = self.database, caller = caller, calling_object = self, on_answer = self.on_answer }:fork(destinations, 
      { 
        callee_id_number = destination.number, 
        timeout = self.agent_timeout,
        send_ringing = ( dialplan_object.send_ringing_to_gateways and caller.from_gateway ),
      });  
    self.log:info('ACD ', self.id, ' CALL_AGENTS - success, fork_index: ', result.fork_index);
    if result.fork_index then
      result.destination = destinations[result.fork_index];
    end   
    return result;
  else
    for index, destination in ipairs(destinations) do
      if os.time() > (self.start_time + self.timeout) and caller.session:ready() then
        self.log:info('ACD ', self.id, ' CALL_AGENTS - timeout');
        return { disposition = 'ACD_TIMEOUT', code = 480, phrase = 'Timeout' }
      end

      self.log:info('ACD ', self.id, ' CALL_AGENT - ', destination.type, '=', destination.id, ', timeout: ', self.agent_timeout);
      result = dialplan.sip_call.SipCall:new{ log = self.log, database = self.database, caller = caller, calling_object = self, on_answer = self.on_answer }:fork({ destination }, 
        { 
          callee_id_number = destination.number, 
          timeout = self.agent_timeout,
          send_ringing = ( dialplan_object.send_ringing_to_gateways and caller.from_gateway ),
        }); 
      if result.disposition == 'SUCCESS' then
        self.log:info('ACD ', self.id, ' CALL_AGENTS - success, agent_id: ', destination.data);
        self:agent_update_call(destination.data);
        result.destination = destination;
        return result;
      end
    end
  end

  return { disposition = 'ACD_NO_AGENTS', code = 480, phrase = 'No active agents' }
end


function AutomaticCallDistributor.run(self, dialplan_object, caller, destination)
  require 'common.str'

  local callers_count = self:callers_count();
  local active_agents = self:agents_active();
  local available_agents = self:agents_available();
  local position = self:call_position();
  
  if self.leave:find('timeout') then
    self.timeout = dialplan_object.dial_timeout_active;
  else
    self.timeout = 86400;
  end

  self.log:info('ACD ', self.id,' - ', self.class, '=', self.id, '/', self.uuid, ', acd_caller=', self.acd_caller_id, ', callers: ', callers_count, ', agents: ', #available_agents, '/', #active_agents, ', position: ', position + 1, ', music: ', tostring(self.music));

  if self.join == 'agents_active' and #active_agents == 0 then
    self.log:info('ACD ', self.id, ' - no agents active');
    return { disposition = 'ACD_NO_AGENTS', code = 480, phrase = 'No agents' }
  end

  if self.join == 'agents_available' and #available_agents == 0 then
    self.log:info('ACD ', self.id, ' - no agents available');
    return { disposition = 'ACD_NO_AGENTS', code = 480, phrase = 'All agents busy' }
  end

  if not common.str.blank(self.music) then
    caller:set_variable('ringback', self.music);
  else
    self.music = false;
  end

  if self.music then
    caller.session:answer();
  else
    caller:set_variable('instant_ringback', true);
  end

  self.start_time = os.time();
  caller:sleep(500);
  local acd_status = 'waiting';
  self:caller_update({status = acd_status});

  local retry_timeout = nil;
  local result = { disposition = 'ACD_NO_AGENTS', code = 480, phrase = 'No active agents' }

  if self.greeting then
    caller.session:sayPhrase('acd_greeting', self.greeting);
  end

  if self.announce_position then
    local current_position = self:call_position();
    if tonumber(current_position) then
      caller.session:sayPhrase('acd_announce_position_enter', tonumber(current_position) + 1);
    end
  end

  while acd_status == 'waiting' and caller.session:ready() do
    acd_status = self:wait_play_music(caller, self.timeout - (os.time() - self.start_time), retry_timeout, self.music);
    self.log:info('ACD ', self.id, ' PROCESS - status: ', acd_status, ', wait_time: ', (os.time() - self.start_time));
    
    if not caller.session:ready() then
      acd_status = 'abandoned';
      break;
    elseif os.time() >= (self.start_time + self.timeout) then
      acd_status = 'timeout';
      break;
    elseif acd_status == 'no_agents' then
      break;
    elseif acd_status == 'call_agents' then
      if self.announce_call_agents ~= '' then
        caller.session:sayPhrase('acd_announce_call_agents', self.announce_call_agents);
      end

      result = self:call_agents(dialplan_object, caller, destination);
      self.log:info('ACD ', self.id, ' PROCESS - result: ', result.disposition, ', code: ', result.code, ', wait_time: ', (os.time() - self.start_time));

      if result.disposition == 'SUCCESS' then
        acd_status = 'success';
        break;
      elseif os.time() < (self.start_time + self.timeout) then
        acd_status = 'waiting';
      else
        break;
      end
    elseif acd_status == 'announce_position' then
      acd_status = 'waiting';
      if tostring(self.announce_position) == '0' then
        caller.session:sayPhrase('acd_announce_position_change', caller:to_i('acd_position'));
      else
        caller.session:sayPhrase('acd_announce_position_periodic', caller:to_i('acd_position'));
      end
    end

    retry_timeout = tonumber(self.record.retry_timeout);
  end

  if self.goodbye and caller.session:ready() then
    caller.session:sayPhrase('acd_goodbye', self.goodbye);
  end
  self.log:info('ACD ', self.id, ' EXIT - status: ', acd_status, ', wait_time: ', (os.time() - self.start_time));

  return result;
end
