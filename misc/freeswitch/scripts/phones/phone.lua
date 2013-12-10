-- Gemeinschaft 5 module: phone class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

Phone = {}

-- create phone object
function Phone.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.database = arg.database;
  return object;
end


function Phone.list_by_sql(self, sql_query)
  local account_phones = {};

  self.database:query(sql_query, function(account_entry)
    local phone = Phone:new(self, {object = parent_class});
    phone.record = account_entry;
    phone.record.ieee_name = common.str.downcase(account_entry.ieee_name);

    if phone.record.ieee_name == 'snom technology ag' then
      require 'phones.snom';
      phone.model = phones.snom.Snom:new{ log = self.log };
    elseif account_entry.ieee_name == 'siemens enterprise communicationsgmbh & co. kg' then
      require 'phones.siemens';
      phone.model = phones.siemens.Siemens:new{ log = self.log };
    elseif phone.record.ieee_name == 'xiamen yealink network technology co.,ltd' then
      require 'phones.yealink';
      phone.model = phones.yealink.Yealink:new{ log = self.log };
    elseif phone.record.ieee_name == 'gigaset communications gmbh' then
      require 'phones.gigaset';
      phone.model = phones.gigaset.Gigaset:new{ log = self.log };
    end
    table.insert(account_phones, phone);
  end)

  return account_phones;
end

-- Find a hot-deskable phone by sip-account
function Phone.find_all_hot_deskable_by_account(self, account_id)
  require 'common.str'

  local sql_query = 'SELECT \
  `b`.`id`, `b`.`mac_address`, `b`.`ip_address`, `b`.`http_user`, `b`.`http_password`, `b`.`phoneable_type`, `b`.`phoneable_id`, \
  `b`.`tenant_id`, `b`.`fallback_sip_account_id`, `d`.`ieee_name` \
  FROM `phone_sip_accounts` `a` \
  JOIN `phones` `b` ON `a`.`phone_id` = `b`.`id` \
  JOIN `phone_models` `c` ON `b`.`phone_model_id` = `c`.`id` \
  JOIN `manufacturers` `d` ON `c`.`manufacturer_id` = `d`.`id` \
  WHERE `b`.`hot_deskable` IS TRUE \
  AND `c`.`state` = "active" \
  AND `d`.`state` = "active" \
  AND `a`.`sip_account_id` = ' .. tonumber(account_id);

  local account_phones = self:list_by_sql(sql_query);

  if #account_phones == 0 then
    sql_query = 'SELECT `b`.`id`, `b`.`mac_address`, `b`.`ip_address`, `b`.`http_user`, `b`.`http_password`, `b`.`phoneable_type`, `b`.`phoneable_id`, \
    `b`.`tenant_id`, `b`.`fallback_sip_account_id`, `d`.`ieee_name` \
    FROM `phones` `b` \
    JOIN `phone_models` `c` ON `b`.`phone_model_id` = `c`.`id` \
    JOIN `manufacturers` `d` ON `c`.`manufacturer_id` = `d`.`id` \
    WHERE `b`.`hot_deskable` IS TRUE \
    AND `c`.`state` = "active" \
    AND `d`.`state` = "active" \
    AND `b`.`fallback_sip_account_id` = ' .. tonumber(account_id);

    account_phones = self:list_by_sql(sql_query);
  end

  return account_phones;
end


function Phone.find_hot_deskable_by_account(self, account_id)
  return self:find_all_hot_deskable_by_account(account_id)[1];
end


function Phone.phoneable_set(self, phoneable_id, phoneable_type)
  sql_query = 'UPDATE `phones` SET `phoneable_type` = "' .. phoneable_type ..'", `phoneable_id` = ' .. phoneable_id .. ' \
    WHERE `id` = ' .. tonumber(self.record.id);
  self.database:query(sql_query);
end

function Phone.logout(self, account_id)
  local tenant_id = tonumber(self.record.tenant_id);

  if not tenant_id then
    self.log:info('PHONE_LOGOUT - tenant not found');
    return false;
  end

  self:phoneable_set(tenant_id, 'Tenant');

  if account_id then
    sql_query = 'DELETE FROM `phone_sip_accounts` WHERE `sip_account_id` = ' .. tonumber(account_id);
    self.database:query(sql_query);
  end

  sql_query = 'DELETE FROM `phone_sip_accounts` WHERE `phone_id` = ' .. self.record.id;
  return self.database:query(sql_query);
end

function Phone.login(self, account_id, owner_id, owner_type)
  self:phoneable_set(owner_id, owner_type);
  sql_query = 'INSERT INTO `phone_sip_accounts` (`phone_id`, `sip_account_id`, `position`, `created_at`, `updated_at`) \
      VALUES ('.. tonumber(self.record.id) .. ', '.. tonumber(account_id) .. ', 1,  NOW(),  NOW())';

  return self.database:query(sql_query);
end

function Phone.resync(self, arg)
  local result = nil;

  if self.record then
    arg.ip_address = arg.ip_address or self.record.ip_address;
    arg.http_user = arg.http_user or self.record.http_user;
    arg.http_password = arg.http_password or self.record.http_password;
  end

  if self.model then
    result = self.model:resync(arg);
  else
    self.log:notice('PHONE_RESYNC phone model not found - trying Snom resync');
    require 'phones.snom';
    result = phones.snom.Snom:new{ log = self.log }:resync(arg);
  end

  if self.record and self.record.id then
    self:resync_extension_modules(arg);
  end

  return result;
end


function Phone.resync_extension_modules(self, arg)
  require('common.object');
  local object_class = common.object.Object:new{ log = self.log };
 
  local sql_query = 'SELECT * FROM `extension_modules` WHERE `active` IS TRUE AND `phone_id` = ' .. common.str.to_i(self.record.id);
  self.database:query(sql_query, function(extension_module)
    local extension_module_class, error_message = object_class:load_one('phones.' .. extension_module.model);
    if not extension_module_class then
      self.log:error('RESYNC_EXTENSION_MODULE - unsupported model: ', extension_module.model, ', error: ', error_message);
    end

    arg.ip_address = extension_module.ip_address;
    local result = extension_module_class:new{log = self.log}:resync(arg);
    self.log:debug('RESYNC_EXTENSION_MODULE - ', extension_module_class.class, '=', extension_module.id, ', mac_address: ', extension_module.mac_address, ', ip_address: ', extension_module.ip_address, ', executed: ', tostring(result));
  end);
end
