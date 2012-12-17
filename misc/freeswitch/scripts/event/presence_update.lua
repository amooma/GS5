
module(...,package.seeall)

function handler_class()
  return PresenceUpdate
end

ACCOUNT_RECORD_TIMEOUT = 120;

PresenceUpdate = {}

function PresenceUpdate.new(self, arg)
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

  return object;
end


function PresenceUpdate.event_handlers(self)
  return { 
    PRESENCE_PROBE = { [true] = self.presence_probe }, 
    CUSTOM = { ['sofia::register'] = self.sofia_register, ['sofia::unregister'] = self.sofia_ungerister },
    PRESENCE_IN = { [true] = self.presence_in },
  }
end


function PresenceUpdate.presence_probe(self, event)
  local DIALPLAN_FUNCTION_PATTERN = '^f[_%-].*';

  require 'common.str'
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
  self.log:debug('[', account, '] PRESENCE_UPDATE - flushing account cache on register');
  self.presence_accounts[account] = nil;
end


function PresenceUpdate.sofia_ungerister(self, event)
  local account = event:getHeader('from-user');
  self.log:debug('[', account, '] PRESENCE_UPDATE - flushing account cache on unregister');
  self.presence_accounts[account] = nil;
end


function PresenceUpdate.presence_in(self, event)
  if not event:getHeader('status') then
    return
  end

  local account, domain = common.str.partition(event:getHeader('from'), '@');
  local direction = tostring(event:getHeader('presence-call-direction'))
  local state = event:getHeader('presence-call-info-state');
  local uuid = event:getHeader('Unique-ID');
  local caller_id =  event:getHeader('Caller-Caller-ID-Number');

  if direction == 'inbound' then
    self.log:info('[', uuid,'] PRESENCE_INBOUND: account: ', account, ', state: ', state);
    self:sip_account(true, account, domain, state, uuid);
  elseif direction == 'outbound' then
    self.log:info('[', uuid,'] PRESENCE_OUTBOUND: account: ', account, ', state: ', state, ', caller: ', caller_id);
    self:sip_account(false, account, domain, state, uuid, caller_id);
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
  require 'common.call_forwarding'
  local call_forwarding = common.call_forwarding.CallForwarding:new{ log=self.log, database=self.database, domain=domain }:find_by_id(call_forwarding_id);
            
  require 'common.str'
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
    require 'dialplan.presence'
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
    require 'dialplan.presence'
    local presence_class = dialplan.presence.Presence:new{
      log = self.log,
      database = self.database,
      domain = domain,
      accounts = {'f-acdmtg-' .. member_id},
      uuid = 'acd_agent_' .. member_id
    }:set(status);
  end
end


function PresenceUpdate.sip_account(self, inbound, account, domain, status, uuid, caller_id)
  local status_map = { progressing = 'early', alerting = 'confirmed', active = 'confirmed' }

  if not self.account_record[account] or ((os.time() - self.account_record[account].created_at) > ACCOUNT_RECORD_TIMEOUT) then
    self.log:debug('[', uuid,'] PRESENCE - retrieve account data - account: ', account);

    require 'common.sip_account'
    local sip_account = common.sip_account.SipAccount:new{ log = self.log, database = self.database }:find_by_auth_name(account);

    if not sip_account then
      return
    end

    require 'common.phone_number'
    local phone_numbers = common.phone_number.PhoneNumber:new{ log = self.log, database = self.database }:list_by_owner(sip_account.id, sip_account.class);

    self.account_record[account] = { id = sip_account.id, class = sip_account.class, phone_numbers = phone_numbers, created_at = os.time() }
  end

  require 'dialplan.presence'
  local result = dialplan.presence.Presence:new{
    log = self.log,
    database = self.database,
    inbound = inbound,
    domain = domain,
    accounts = self.account_record[account].phone_numbers,
    uuid = uuid
  }:set(status_map[status] or 'terminated', caller_id);
end
