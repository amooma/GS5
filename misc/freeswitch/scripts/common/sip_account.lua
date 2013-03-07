-- Gemeinschaft 5 module: sip account class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

SipAccount = {}

-- Create SipAccount object
function SipAccount.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.class = 'sipaccount';
  self.log = arg.log;
  self.database = arg.database;
  self.record = arg.record;
  self.domain = arg.domain;
  return object;
end


function SipAccount.find_by_sql(self, where)
  local sql_query = 'SELECT \
    `a`.`id`, \
    `a`.`uuid`, \
    `a`.`auth_name`, \
    `a`.`caller_name`, \
    `a`.`password`, \
    `a`.`voicemail_pin`, \
    `a`.`tenant_id`, \
    `a`.`sip_domain_id`, \
    `a`.`call_waiting`, \
    `a`.`clir`, \
    `a`.`clip`, \
    `a`.`clip_no_screening`, \
    `a`.`sip_accountable_type`,  \
    `a`.`sip_accountable_id`, \
    `a`.`hotdeskable`, \
    `a`.`gs_node_id`, \
    `a`.`language_code`, \
    `b`.`host`, \
    `c`.`sip_host`, \
    `c`.`profile_name` \
    FROM `sip_accounts` `a` \
    JOIN `sip_domains` `b` ON `a`.`sip_domain_id` = `b`.`id`  \
    LEFT JOIN `sip_registrations` `c` ON `a`.`auth_name` = `c`.`sip_user` \
    WHERE ' .. where .. ' LIMIT 1';

  local sip_account = nil;
  self.database:query(sql_query, function(account_entry)
    sip_account = SipAccount:new(self);
    sip_account.record = account_entry;
    sip_account.id = tonumber(account_entry.id);
    sip_account.uuid = account_entry.uuid;
  end)

  return sip_account;
end


-- find sip account by id
function SipAccount.find_by_id(self, id)
  local sql_query = '`a`.`id`= ' .. tonumber(id);
  return self:find_by_sql(sql_query);
end

-- find sip account by uuid
function SipAccount.find_by_uuid(self, uuid)
  local sql_query = '`a`.`uuid`= "' .. uuid .. '"';
  return self:find_by_sql(sql_query);
end

-- Find SIP Account by auth_name
function SipAccount.find_by_auth_name(self, auth_name, domain)
  local sql_query = '`a`.`auth_name`= "' .. auth_name .. '"';

  if domain then
    sql_query = sql_query .. ' AND `b`.`host` = "' .. domain .. '"';
  end

  return self:find_by_sql(sql_query);
end

-- retrieve Phone Numbers for SIP Account
function SipAccount.phone_numbers(self, id)
  id = id or self.record.id;
  if not id then
    return false;
  end

  local sql_query = "SELECT * FROM `phone_numbers` WHERE `phone_numberable_type` = \"SipAccount\" AND `phone_numberable_id`=" .. self.record.id;
  local phone_numbers = {}

  self.database:query(sql_query, function(entry)
    table.insert(phone_numbers,entry.number);
  end)

  return phone_numbers;
end

-- retrieve Ringtone for SIP Account
function SipAccount.ringtone(self, id)
  id = id or self.record.id;
  if not id then
    return false;
  end

  local sql_query = "SELECT * FROM `ringtones` WHERE `ringtoneable_type` = \"SipAccount\" AND `ringtoneable_id`=" .. self.record.id .. " LIMIT 1";
  local ringtone = nil;

  self.database:query(sql_query, function(entry)
    ringtone = entry;
  end)

  return ringtone;
end

function SipAccount.send_text(self, text)
  local event = freeswitch.Event("NOTIFY");
  event:addHeader("profile", "gemeinschaft");
  event:addHeader("event-string", "text");
  event:addHeader("user", self.record.auth_name);
  event:addHeader("host", self.record.host);
  event:addHeader("content-type", "text/plain");
  event:addBody(text);
  event:fire();
end


function SipAccount.call_state(self)
  local sql_query = 'SELECT `callstate` FROM `detailed_calls` \
    WHERE `presence_id` LIKE "' .. self.record.auth_name .. '@%" \
    OR `b_presence_id` LIKE "' .. self.record.auth_name .. '@%" \
    LIMIT 1';

  return self.database:query_return_value(sql_query);
end


function SipAccount.call_forwarding_on(self, service, destination, destination_type, timeout, source)
  
  if not self.call_forwarding then
    require 'common.call_forwarding';
    self.call_forwarding = common.call_forwarding.CallForwarding:new{ log = self.log, database = self.database, parent = self, domain = self.domain };
  end

  return self.call_forwarding:call_forwarding_on(service, destination, destination_type, timeout, source)
end


function SipAccount.call_forwarding_off(self, service, source, delete)
  if not self.call_forwarding then
    require 'common.call_forwarding';
    self.call_forwarding = common.call_forwarding.CallForwarding:new{ log = self.log, database = self.database, parent = self, domain = self.domain };
  end

  return self.call_forwarding:call_forwarding_off(service, source, delete)
end
