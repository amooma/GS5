
module(...,package.seeall)

function handler_class()
  return PresenceUpdate
end

ACCOUNT_RECORD_TIMEOUT = 120;

PresenceUpdate = {}

function PresenceUpdate.new(self, arg)
  require 'common.sip_account';
  require 'dialplan.presence';
  require 'common.str';
  require 'common.phone_number';
  require 'common.fapi';
  require 'common.configuration_table';

  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.class = 'presenceupdate'
  self.database = arg.database;
  self.domain = arg.domain;
  self.presence_accounts = {}
  self.account_record = {}

  self.config = common.configuration_table.get(self.database, 'presence_update');
  self.config = self.config or {};
  self.config.trigger = self.config.trigger or {
    sip_account_presence = true,
    sip_account_register = true,
    sip_account_unregister = true,
  };
  return object;
end


function PresenceUpdate.event_handlers(self)
  return { 
    PRESENCE_PROBE = { [true] = self.presence_probe }, 
    CUSTOM = { ['sofia::register'] = self.sofia_register, ['sofia::unregister'] = self.sofia_ungerister },
    PRESENCE_IN = { [true] = self.presence_in },
  }
end


function PresenceUpdate.retrieve_sip_account(self, account, uuid)
  uuid = uuid or 'presence_update';
  
  if not self.account_record[account] or ((os.time() - self.account_record[account].created_at) > ACCOUNT_RECORD_TIMEOUT) then
    self.log:debug('[', uuid,'] PRESENCE - retrieve account data - account: ', account);
    
    local sip_account = common.sip_account.SipAccount:new{ log = self.log, database = self.database }:find_by_auth_name(account);
    if not sip_account then
      return
    end
    
    local phone_numbers = common.phone_number.PhoneNumber:new{ log = self.log, database = self.database }:list_by_owner(sip_account.id, sip_account.class);

    self.account_record[account] = { id = sip_account.id, class = sip_account.class, phone_numbers = phone_numbers, created_at = os.time() }
  end

  return self.account_record[account];
end


function PresenceUpdate.presence_probe(self, event)
  local DIALPLAN_FUNCTION_PATTERN = '^f[_%-].*';

  local event_to = event:getHeader('to');
  local event_from = event:getHeader('from');
  local probe_type = event:getHeader('probe-type');
  local account, domain = common.str.partition(event_from, '@');
  local subscription, domain = common.str.partition(event_to, '@');

  self.log:debug('[', account, '] PRESENCE_UPDATE - subscription: ', subscription,', type: ', probe_type);
  if (not self.presence_accounts[account] or not self.presence_accounts[account][subscription]) and subscription:find(DIALPLAN_FUNCTION_PATTERN) then
    if not self.presence_accounts[account] then
      self.presence_accounts[account] = {};
    end
    if not self.presence_accounts[account][subscription] then
      self.presence_accounts[account][subscription] = {};
    end
    self:update_function_presence(account, domain, subscription);
  end
end


function PresenceUpdate.sofia_register(self, event)
  local account = event:getHeader('from-user');
  local timestamp = event:getHeader('Event-Date-Timestamp');

  local sip_account = self:retrieve_sip_account(account, account);

  self.log:debug('[', account, '] PRESENCE_UPDATE - flushing account cache on register');
  self.presence_accounts[account] = nil;
end


function PresenceUpdate.sofia_ungerister(self, event)
  local account = event:getHeader('from-user');
  local timestamp = event:getHeader('Event-Date-Timestamp');

  local sip_account = self:retrieve_sip_account(account, account);

  self.log:debug('[', account, '] PRESENCE_UPDATE - flushing account cache on unregister');
  self.presence_accounts[account] = nil;
end


function PresenceUpdate.presence_in(self, event)
  local account, domain = common.str.partition(event:getHeader('from'), '@');
  local call_direction = tostring(event:getHeader('presence-call-direction') or event:getHeader('call-direction'))
  local state = event:getHeader('presence-call-info-state');
  local uuid = event:getHeader('Unique-ID');
  local caller_id =  event:getHeader('Caller-Caller-ID-Number');
  local protocol = tostring(event:getHeader('proto'));
  local timestamp = event:getHeader('Event-Date-Timestamp');
  local direction = nil;

  if call_direction == 'inbound' then
    direction = true;
  elseif call_direction == 'outbound' then
    direction = false;
  end

  if tostring(event:getHeader('event_origin')) == 'gemeinschaft' then
    self.log:debug('[', uuid,'] PRESENCE_', call_direction:upper(),'_LOOP ignored - protocol: ', protocol, ', account: ', account, ', state: ', state);
  elseif protocol == 'conf' then    
    state = event:getHeader('answer-state');
    local login = tostring(event:getHeader('proto'));
    self.log:info('[', uuid,'] PRESENCE_CONFERENCE_', call_direction:upper(), ' ', common.str.to_i(account), ' - identifier: ', account, ', state: ', state);
    self:conference(direction, account, domain, state, uuid);
  elseif protocol == 'sip' or protocol == 'any' then
    if common.str.blank(state) then
      state = event:getHeader('answer-state');
    end
    if protocol == 'sip' and common.str.blank(state) then
      self.log:debug('[', uuid,'] PRESENCE_', call_direction:upper(),' no state - protocol: ', protocol, ', account: ', account);
      return;
    end
    self.log:info('[', uuid,'] PRESENCE_', call_direction:upper(),' - protocol: ', protocol, ', account: ', account, ', state: ', state);
    self:sip_account(direction, account, domain, state, uuid, caller_id, timestamp);
  else
    self.log:info('[', uuid,'] PRESENCE_', call_direction:upper(),' unhandled protocol: ', protocol, ', account: ', account, ', state: ', state);
  end
end


function PresenceUpdate.update_function_presence(self, account, domain, subscription)
  local parameters = common.str.to_a(subscription, '_%-');
  local fid = parameters[2];
  local function_parameter = parameters[3];

  if not fid then
    self.log:error('[', account, '] PRESENCE_UPDATE - no function specified');
    return;
  end

  if fid == 'cftg' and tonumber(function_parameter) then
    self:call_forwarding(account, domain, function_parameter);
  elseif fid == 'hgmtg' then
    self:hunt_group_membership(account, domain, function_parameter);
  elseif fid == 'acdmtg' then
    self:acd_membership(account, domain, function_parameter);
  end

end


function PresenceUpdate.call_forwarding(self, account, domain, call_forwarding_id)
  require 'common.call_forwarding';

  local call_forwarding = common.call_forwarding.CallForwarding:new{ log=self.log, database=self.database, domain=domain }:find_by_id(call_forwarding_id);     
  if call_forwarding and common.str.to_b(call_forwarding.record.active) then
    local destination_type = tostring(call_forwarding.record.call_forwardable_type):lower()
    
    self.log:debug('[', account, '] PRESENCE_UPDATE - updating call forwarding presence - id: ', call_forwarding_id, ', destination: ', destination_type);
    
    if destination_type == 'voicemail' then
      call_forwarding:presence_set('early');
    else
      call_forwarding:presence_set('confirmed');
    end
  end
end


function PresenceUpdate.hunt_group_membership(self, account, domain, member_id)
  local sql_query = 'SELECT `active` FROM `hunt_group_members` WHERE `active` IS TRUE AND `id`=' .. tonumber(member_id) .. ' LIMIT 1';
  local status = self.database:query_return_value(sql_query);

  if status then
    self.log:debug('[', account, '] PRESENCE_UPDATE - updating hunt group membership presence - id: ', member_id);
    local presence_class = dialplan.presence.Presence:new{
      log = self.log,
      database = self.database,
      domain = domain,
      accounts = {'f-hgmtg-' .. member_id},
      uuid = 'hunt_group_member_' .. member_id
    }:set('confirmed');
  end
end


function PresenceUpdate.acd_membership(self, account, domain, member_id)
  local sql_query = 'SELECT `status` FROM `acd_agents` WHERE `status` = "active" AND `id`=' .. tonumber(member_id) .. ' LIMIT 1';
  local status = self.database:query_return_value(sql_query);

  if status then
    self.log:debug('[', account, '] PRESENCE_UPDATE - updating ACD membership presence - id: ', member_id);
    local presence_class = dialplan.presence.Presence:new{
      log = self.log,
      database = self.database,
      domain = domain,
      accounts = {'f-acdmtg-' .. member_id},
      uuid = 'acd_agent_' .. member_id
    }:set(status);
  end
end


function PresenceUpdate.sip_account(self, inbound, account, domain, status, uuid, caller_id, timestamp)
  local status_map = { progressing = 'early', alerting = 'confirmed', active = 'confirmed' }
  
  local sip_account = self:retrieve_sip_account(account, uuid);
  if not sip_account then
    return;
  end

  dialplan.presence.Presence:new{
    log = self.log,
    database = self.database,
    inbound = inbound,
    domain = domain,
    accounts = sip_account.phone_numbers,
    uuid = uuid
  }:set(status_map[status] or 'terminated', caller_id);

end


function PresenceUpdate.conference(self, inbound, account, domain, status, uuid)
  
  dialplan.presence.Presence:new{
    log = self.log,
    database = self.database,
    inbound = inbound,
    domain = domain,
    accounts = { account },
    uuid = uuid
  }:set(status or 'terminated');
end


function PresenceUpdate.trigger_rails(self, account, status, timestamp, uuid)
  if account.class == 'sipaccount' then
    local command = 'http_request.lua ' .. tostring(uuid) .. ' http://127.0.0.1/trigger/sip_account_update/' .. tostring(account.id) .. '?timestamp=' .. timestamp .. '&status=' .. tostring(status);
    common.fapi.FApi:new():execute('luarun', command);
  end
end
