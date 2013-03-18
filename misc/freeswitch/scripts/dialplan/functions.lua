-- DialplanModule: Functions
--
module(...,package.seeall)

Functions = {}

-- Create Functions object
function Functions.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self)
  self.__index = self
  self.log = arg.log
  self.database = arg.database
  self.domain = arg.domain
  return object
end

function Functions.ensure_caller_sip_account(self, caller)
  if caller.account and  caller.account.class == 'sipaccount' then
    return caller.account;
  end
end

function Functions.dialplan_function(self, caller, dialed_number)
  local parameters = common.str.to_a(dialed_number, '%-');
  if not parameters[2] then
    return { continue = false, code = 484, phrase = 'Malformed function parameters', no_cdr = true };
  end
  local fid = tostring(parameters[2]);
  local result = { continue = false, code = 404, phrase = 'Function not found', no_cdr = true };

  self.log:debug('DIALPLAN_FUNCTION - execute: ', dialed_number);

  if fid == "ta" then
    result = self:transfer_all(caller, parameters[3]);
  elseif fid == "ia" then
    result = self:intercept_any_number(caller, parameters[3]);
  elseif fid == "ig" then
    result = self:group_pickup(caller, parameters[3]);
  elseif fid == "anc" then
    result = self:account_node_change(caller);
  elseif fid == "li" then
    result = self:user_login(caller, parameters[3], parameters[4]);
  elseif fid == "lo" then
    result = self:user_logout(caller);
  elseif fid == "lir" then
    result = self:user_login_redirect(caller, parameters[3], parameters[4]);
  elseif fid == "loaon" then
    result = self:user_auto_logout(caller, true);
  elseif fid == "loaoff" then
    result = self:user_auto_logout(caller, false);
  elseif fid == "redial" then
    result = self:redial(caller);
  elseif fid == "dcliroff" then
    result = self:dial_clir_off(caller, parameters[3]);
  elseif fid == "dcliron" then
    result = self:dial_clir_on(caller, parameters[3]);
  elseif fid == "cliron" then
    result = self:clir_on(caller);
  elseif fid == "cliroff" then
    result = self:clir_off(caller);
  elseif fid == "clipon" then
    result = self:clip_on(caller);
  elseif fid == "clipoff" then
    result = self:clip_off(caller);
  elseif fid == "cwaoff" then
    result = self:callwaiting_off(caller);
  elseif fid == "cwaon" then
    result = self:callwaiting_on(caller);
  elseif fid == "cfoff" then
    result = self:call_forwarding_off(caller);
  elseif fid == "cfdel" then
    result = self:call_forwarding_off(caller, nil, true);
  elseif fid == "cfu" then
    result = self:call_forwarding_on(caller, 'always', parameters[3], 'PhoneNumber');
  elseif fid == "cfuoff" then
    result = self:call_forwarding_off(caller, 'always');
  elseif fid == "cfudel" then
    result = self:call_forwarding_off(caller, 'always', true);
  elseif fid == "cfutg" then
    result = self:call_forwarding_toggle(caller, 'always', parameters[3]);
  elseif fid == "cfn" then
    result = self:call_forwarding_on(caller, 'noanswer', parameters[3], 'PhoneNumber', parameters[4]);
  elseif fid == "cfnoff" then
    result = self:call_forwarding_off(caller, 'noanswer');
  elseif fid == "cfndel" then
    result = self:call_forwarding_off(caller, 'noanswer', true); 
  elseif fid == "cfo" then
    result = self:call_forwarding_on(caller, 'offline', parameters[3], 'PhoneNumber');
  elseif fid == "cfooff" then
    result = self:call_forwarding_off(caller, 'offline');
  elseif fid == "cfodel" then
    result = self:call_forwarding_off(caller, 'offline', true);
  elseif fid == "cfb" then
    result = self:call_forwarding_on(caller, 'busy', parameters[3], 'PhoneNumber');
  elseif fid == "cfboff" then
    result = self:call_forwarding_off(caller, 'busy');
  elseif fid == "cfbdel" then
    result = self:call_forwarding_off(caller, 'busy', true);
  elseif fid == "vmleave" then
    result = self:voicemail_message_leave(caller, parameters[3]);
  elseif fid == "vmcheck" then
    result = self:voicemail_check(caller, parameters[3]);
  elseif fid == "vmtg" then
    result = self:call_forwarding_toggle(caller, nil, parameters[3]);
  elseif fid == "acdmtg" then
    result = self:acd_membership_toggle(caller, parameters[3], parameters[4]);
  elseif fid == "e164" then
    result = "+" .. tostring(parameters[3]);
  elseif fid == "hangup" then
    result = self:hangup(caller, parameters[3], parameters[4]);
  elseif fid == "cpa" then
    result = self:call_parking_inout(caller, parameters[3], parameters[4]);
  elseif fid == "cpai" then
    result = self:call_parking_inout_index(caller, parameters[3]);
  end

  return result or { continue = false, code = 505, phrase = 'Error executing function', no_cdr = true };
end


function Functions.transfer_all(self, caller, destination_number)
  local caller_sip_account = self:ensure_caller_sip_account(caller);
  if not caller_sip_account then
    self.log:error('TRANSFER_ALL - incompatible caller');
    return { continue = false, code = 403, phrase = 'Incompatible caller' }
  end

  self.log:info('TRANSFER_ALL - initiator: ', caller.account.class, '=', caller.account.id, '/', caller.account.uuid, ', number: ', destination_number);

  local sql_query = 'SELECT `uuid`, `b_uuid`, `callee_number`, `caller_id_number`, `sip_account_id`, `b_sip_account_id` \
    FROM `calls_active` WHERE `sip_account_id` = '.. caller.account.id .. ' OR `b_sip_account_id` = '.. caller.account.id;
  local index = 1;
  self.database:query(sql_query, function(call_entry)
    if not common.str.blank(call_entry.uuid) and tostring(caller.account.id) ~= tostring(call_entry.sip_account_id) then
      self.log:info('TRANSFER_ALEG ', index, ' - channel/', call_entry.uuid, '|', call_entry.caller_id_number);
      freeswitch.API():execute("uuid_transfer", call_entry.uuid .. " " .. destination_number);
    end
    if not common.str.blank(call_entry.b_uuid) and tostring(caller.account.id) ~= tostring(call_entry.b_sip_account_id)  then
      self.log:info('TRANSFER_BLEG ', index, ' - channel/', call_entry.b_uuid, '|', call_entry.callee_number);
      freeswitch.API():execute("uuid_transfer", call_entry.b_uuid .. " " .. destination_number);
    end
    index = index + 1;
  end)

  return { continue = true, number = destination_number }
end


function Functions.intercept_any_number(self, caller, destination_number)
  require 'common.phone_number'
  local phone_number = common.phone_number.PhoneNumber:new{ log = self.log, database = self.database }:find_by_number(destination_number);

  if not phone_number or not phone_number.record then
    self.log:notice('FUNCTION_INTERCEPT_ANY_NUMBER - number not found: ', destination_number);
    return { continue = false, code = 404, phrase = 'Number not found', no_cdr = true };
  end

  require 'common.object';
  local phone_numberable = common.object.Object:new{ log = self.log, database = self.database}:find{class = phone_number.record.phone_numberable_type, id = phone_number.record.phone_numberable_id};

  if not phone_numberable then
    self.log:notice('FUNCTION_INTERCEPT_ANY_NUMBER - numberable not found: ', phone_number.record.phone_numberable_type, '=', phone_number.record.phone_numberable_id);
    return { continue = false, code = 404, phrase = 'Destination not found', no_cdr = true };
  end

  require 'common.group';
  local group_class = common.group.Group:new{ log = self.log, database = self.database };
  local group_ids = group_class:union(common.array.try(caller, 'auth_account.group_ids'), common.array.try(caller, 'auth_account.owner.group_ids'));
  local target_groups, target_group_ids = group_class:permission_targets(group_ids, 'pickup');
  local destination_group_ids = group_class:union(common.array.try(phone_numberable, 'group_ids'), common.array.try(phone_numberable, 'owner.group_ids'));

  if #group_class:intersection(destination_group_ids, target_group_ids) == 0 then
    self.log:notice('FUNCTION_INTERCEPT_ANY_NUMBER - Groups not found or insufficient permissions, destination:', destination_group_ids, ', target: ', target_group_ids);
    return { continue = false, code = 402, phrase = '"Insufficient permissions', no_cdr = true };
  end

  self.log:info('FUNCTION_INTERCEPT_ANY_NUMBER intercepting call - to: ', phone_numberable.class, '=',phone_numberable.id, '|', destination_number);

  caller:set_variable('gs_pickup_group_pick', 's' .. phone_number.record.phone_numberable_id);
  caller:execute('pickup', 's' .. phone_number.record.phone_numberable_id);

  return { continue = false, code = 200, phrase = 'OK', no_cdr = true }
end


function Functions.group_pickup(self, caller, group_id)
  if not tonumber(group_id) then
    return { continue = false, code = 505, phrase = 'Incompatible destination', no_cdr = true };
  end

  require 'common.group';
  local group_class = common.group.Group:new{ log = self.log, database = self.database };
  local group_ids = group_class:union(common.array.try(caller, 'auth_account.group_ids'), common.array.try(caller, 'auth_account.owner.group_ids'));
  local target_group = group_class:is_target(group_id, 'pickup');

  if not target_group then
    self.log:notice('FUNCTION_GROUP_PICKUP - group=', group_id, ' not found or insufficient permissions');
    return { continue = false, code = 402, phrase = '"Insufficient permissions', no_cdr = true };
  end

  self.log:notice('FUNCTION_GROUP_PICKUP - group=', group_id, '|', target_group);

  caller:set_variable('gs_pickup_group_pick', 'g' .. group_id);
  caller:execute('pickup', 'g' .. group_id);

  return { continue = false, code = 200, phrase = 'OK', no_cdr = true }
end


function Functions.account_node_change(self, caller)
  self.log:info('NODE_CHANGE - caller: ', caller.account_type, '/', caller.account_uuid, ', caller_id: ', caller.caller_id_number);

  -- find caller's sip account
  local caller_sip_account = caller.account;
  if not caller_sip_account or not caller_sip_account.class == 'sipaccount' then
    self.log:notice('LOGIN - caller sip_account not found');
    return { continue = false, code = 404, phrase = 'Account not found', no_cdr = true }
  end

  require 'phones.phone'
  local phone_class = phones.phone.Phone:new{log = self.log, database = self.database}

  -- logout caller phones if caller account is hot-deskable
  local caller_phones = phone_class:find_all_hot_deskable_by_account(caller_sip_account.record.id);
  for index, phone_caller in ipairs(caller_phones) do
    phone_caller:logout(caller_sip_account.record.id);
  end

  self:update_node_change(caller_sip_account, caller.local_node_id);
  caller:answer();
  caller:send_display('Change successful');
  caller.session:sayPhrase('logged_in');

  -- resync caller phones
  for index, phone_caller in ipairs(caller_phones) do
    local result = phone_caller:resync{ auth_name = caller_sip_account.record.auth_name, domain = caller_sip_account.record.host };
    self.log:info('NODE_CHANGE - resync phone - mac: ', phone_caller.record.mac_address, ', ip_address: ', phone_caller.record.ip_address, ', result: ', result);
  end

  return { continue = false, code = 200, phrase = 'OK', no_cdr = true }
end


function Functions.user_login(self, caller, number, pin)
  local PHONE_NUMBER_LEN_MIN = 4;
  local PHONE_NUMBER_LEN_MAX = 12;
  local PIN_LEN_MIN = 4;
  local PIN_LEN_MAX = 12;

  caller:set_variable('destination_number', 'f-li-' .. common.str.to_s(number) .. '-PIN');
  self.log:info('LOGIN - caller: ', caller.account_type, '/', caller.account_uuid, ', caller_id: ', caller.caller_id_number, ', number: ', number);

  if common.str.blank(number) then
    number = caller.session:read(PHONE_NUMBER_LEN_MIN, PHONE_NUMBER_LEN_MAX, 'ivr/ivr-please_enter_extension_followed_by_pound.wav', 3000, '#');
  end

   -- find caller's sip account
  local caller_sip_account = caller.account;
  if not caller_sip_account or not caller_sip_account.class == 'sipaccount' then
    self.log:notice('LOGIN - caller sip_account not found');
    return { continue = false, code = 404, phrase = 'Caller not found', no_cdr = true }
  end

  require 'phones.phone'
  local phone_class = phones.phone.Phone:new{log = self.log, database = self.database}
  
  local caller_phones = phone_class:find_all_hot_deskable_by_account(caller_sip_account.id);
  local caller_phone  = caller_phones[1];

  if not caller_phone then
    self.log:notice('LOGIN - caller phone not found or not hot-deskable');
    local result = phone_class:resync{ auth_name = caller_sip_account.record.auth_name, domain = caller_sip_account.record.host };
    return { continue = false, code = 403, phrase = 'Phone not hot-deskable', no_cdr = true }
  end

  require 'common.phone_number'
  local phone_number = common.phone_number.PhoneNumber:new{log = self.log, database = self.database}:find_by_number(number, {"SipAccount"});

  if not phone_number then
    self.log:notice('LOGIN - number not found or not linked to a sip account - number: ', number);
    return { continue = false, code = 404, phrase = 'Account not found', no_cdr = true }
  end

  require 'common.sip_account'
  local destination_sip_account = common.sip_account.SipAccount:new{ log = self.log, database = self.database }:find_by_id(phone_number.record.phone_numberable_id);

  if not destination_sip_account then
    self.log:notice('LOGIN - account not found - ', phone_number.record.phone_numberable_type, '=', phone_number.record.phone_numberable_id, ', number: ', number);
    return { continue = false, code = 404, phrase = 'Account not found', no_cdr = true }
  end

  self.log:info('LOGIN - destination: ', phone_number.record.phone_numberable_type, '=', destination_sip_account.record.id, 
    ', caller_name: ', destination_sip_account.record.caller_name, ', hotdeskable: ', destination_sip_account.record.hotdeskable);

  if not common.str.to_b(destination_sip_account.record.hotdeskable) then
    self.log:notice('LOGIN - destination sip_account not hot-deskable');
    return { continue = false, code = 404, phrase = 'Destination not hot-deskable', no_cdr = true }
  end

  require 'dialplan.user'
  local user = dialplan.user.User:new{ log = self.log, database = self.database }:find_by_id(destination_sip_account.record.sip_accountable_id);

  if common.str.blank(pin) then
    pin = caller.session:read(PIN_LEN_MIN, PIN_LEN_MAX, 'ivr/ivr-please_enter_pin_followed_by_pound.wav', 3000, '#');
  end

  if not user then
    self.log:notice('LOGIN - user not found - ',  destination_sip_account.record.sip_accountable_type, '=',destination_sip_account.record.sip_accountable_id);
    return { continue = false, code = 403, phrase = 'Authentication failed', no_cdr = true }
  end

  if not user:check_pin(pin) then
    self.log:notice('LOGIN - authentication failed');
    return { continue = false, code = 403, phrase = 'Authentication failed', no_cdr = true }
  end

  -- logout caller phones if caller account is hot-deskable
  if common.str.to_b(caller_sip_account.record.hotdeskable) then
    for index, phone_caller in ipairs(caller_phones) do
      phone_caller:logout(caller_sip_account.record.id);
    end
  end

  local destination_phones = phone_class:find_all_hot_deskable_by_account(destination_sip_account.record.id);
  -- logout destination phones
  for index, phone_destination in ipairs(destination_phones) do
    phone_destination:logout(destination_sip_account.record.id);
  end

  local result = caller_phone:login(destination_sip_account.record.id, destination_sip_account.record.sip_accountable_id, destination_sip_account.record.sip_accountable_type);
  self.log:info('LOGIN - account login - mac: ', caller_phone.record.mac_address, ', ip_address: ', caller_phone.record.ip_address, ', result: ', result);

  if not result then
    return { continue = false, code = 403, phrase = 'Login failed', no_cdr = true }
  end

  caller:answer();
  caller:send_display('Login successful');

  self:update_node_change(destination_sip_account, caller.local_node_id);
  caller:sleep(1000);

  -- resync destination phones
  for index, phone_destination in ipairs(destination_phones) do
    local result = phone_destination:resync{ auth_name = destination_sip_account.record.auth_name, domain = destination_sip_account.record.host };
    self.log:info('LOGIN - resync destination phone - mac: ', phone_destination.record.mac_address, ', ip_address: ', phone_destination.record.ip_address, ', result: ', result);
  end

  -- resync caller phones
  for index, phone_caller in ipairs(caller_phones) do
    local result = phone_caller:resync{ auth_name = caller_sip_account.record.auth_name, domain = caller_sip_account.record.host };
    self.log:info('LOGIN - resync caller phone - mac: ', phone_caller.record.mac_address, ', ip_address: ', phone_caller.record.ip_address, ', result: ', result);
  end

  return { continue = false, code = 200, phrase = 'OK', no_cdr = true }
end


function Functions.user_logout(self, caller)
  self.log:info('LOGOUT - caller: ', caller.account_type, '/', caller.account_uuid, ', caller_id: ', caller.caller_id_number);

  -- find caller's sip account
  local caller_sip_account = caller.account;
  if not caller_sip_account or not caller_sip_account.class == 'sipaccount' then
    self.log:notice('LOGOUT - caller sip_account not found');
    return { continue = false, code = 404, phrase = 'Caller not found', no_cdr = true }
  end

  if not common.str.to_b(caller_sip_account.record.hotdeskable) then
    self.log:notice('LOGOUT - caller sip_account not hot-deskable');
    return { continue = false, code = 404, phrase = 'Caller not hot-deskable', no_cdr = true }
  end

  require 'phones.phone'
  local phone_class = phones.phone.Phone:new{log = self.log, database = self.database}
  
  local caller_phones = phone_class:find_all_hot_deskable_by_account(caller_sip_account.id);
  
  if #caller_phones == 0 then
    self.log:notice('LOGOUT - caller phones not found or not hot-deskable');
    local result = phone_class:resync{ auth_name = caller_sip_account.record.auth_name, domain = caller_sip_account.record.host };
    return { continue = false, code = 403, phrase = 'Phone not hot-deskable', no_cdr = true }
  end

  local result = false;
  for index, phone_caller in ipairs(caller_phones) do
    result = phone_caller:logout(caller_sip_account.record.id);
    self.log:info('LOGOUT - account logout - mac: ', phone_caller.record.mac_address, ', ip_address: ', phone_caller.record.ip_address, ', result: ', result);
  end

  caller:answer();
  caller:send_display('Logout successful');
  caller:sleep(1000);

  -- resync caller phones
  for index, phone_caller in ipairs(caller_phones) do
    local result = phone_caller:resync{ auth_name = caller_sip_account.record.auth_name, domain = caller_sip_account.record.host };
    self.log:info('LOGIN - resync caller phone - mac: ', phone_caller.record.mac_address, ', ip_address: ', phone_caller.record.ip_address, ', result: ', result);
  end

  return { continue = false, code = 200, phrase = 'OK', no_cdr = true }
end


function Functions.update_node_change(self, sip_account, node_id)
  require 'common.sync_log'
  local sync_log_class = common.sync_log.SyncLog:new{ log = self.log, database = self.database, homebase_ip_address = sip_account.record.host }
  
  if tostring(sip_account.record.gs_node_id) ~= tostring(node_id) then
    self.log:info('UPDATE_NODE - from: ', sip_account.record.gs_node_id, ', to: ', node_id, ', sipaccount=', sip_account.record.id, '/', sip_account.record.uuid, '@', node_id, ', caller_name: ', sip_account.record.caller_name);
    sql_query = 'UPDATE `sip_accounts` SET `updated_at` = NOW(), `gs_node_id` = ' .. tonumber(node_id) .. ' WHERE id = ' .. tonumber(sip_account.record.id);
    if self.database:query(sql_query) then
      sync_log_class:insert('SipAccount', { uuid = sip_account.record.uuid, gs_node_id = tonumber(node_id), updated_at = os.date('!%Y-%m-%d %H:%M:%S %Z') }, 'update', { 'gs_node_id', 'updated_at' });
    end
  end

  require 'common.phone_number'
  local phone_numbers = common.phone_number.PhoneNumber:new{log = self.log, database = self.database}:find_all_by_owner(sip_account.record.id, 'SipAccount');
  for number_id, phone_number in pairs(phone_numbers) do
    if tostring(phone_number.record.gs_node_id) ~= tostring(node_id) then
      self.log:info('UPDATE_NODE - from: ', phone_number.record.gs_node_id, ', to: ', node_id, ', phonenumber=', phone_number.record.id, '/', phone_number.record.uuid, '@', node_id, ', number: ', phone_number.record.number);
      sql_query = 'UPDATE `phone_numbers` SET `updated_at` = NOW(), `gs_node_id` = ' .. tonumber(node_id) .. ' WHERE id = ' .. tonumber(number_id);
      
      if self.database:query(sql_query) then
        sync_log_class:insert('PhoneNumber', { uuid = phone_number.record.uuid, gs_node_id = tonumber(node_id), updated_at = os.date('!%Y-%m-%d %H:%M:%S %Z') }, 'update', { 'gs_node_id', 'updated_at' });
      end
    end
  end
end


function Functions.user_login_redirect(self, caller, phone_number, pin)
  -- Remove PIN from destination_number
  caller.session:setVariable("destination_number", "f-li-" .. tostring(phone_number) .. "-PIN");

  -- Redirect to f-li function
  caller.session:execute("redirect", "sip:f-li-" .. tostring(phone_number) .. "-" .. tostring(pin) .. "@" .. caller.domain);
end

-- Set nightly_reboot flag
function Functions.user_auto_logout(self, caller, auto_logout)
  local nightly_reboot = 'FALSE';
  if auto_logout then
    nightly_reboot = 'TRUE';
  end

  -- Ensure a valid sip account
  local caller_sip_account = caller.account;
  if not caller_sip_account or not caller_sip_account.class == 'sipaccount' then
    return { continue = false, code = 403, phrase = 'Incompatible caller', no_cdr = true }
  end

  require "phones.phone"
  local phone_class = phones.phone.Phone:new{log = self.log, database = self.database}
  
  -- Get caller phone
  local caller_phone = phone_class:find_hot_deskable_by_account(caller_sip_account.id);
  if not caller_phone then
    self.log:notice("Caller phone not found or not hot-deskable");
    return { continue = false, code = 401, phrase = 'Phone not hot-deskable', no_cdr = true }
  end

  log:debug("Hot-desking auto log off - caller phone: " .. caller_phone.record.id .. ", mac: " .. caller_phone.record.mac_address);

  sql_query = 'UPDATE `phones` SET `nightly_reboot` = ' .. nightly_reboot .. ' WHERE `id` = ' .. tonumber(caller_phone.record.id);
  
  if not self.database:query(sql_query) then
    self.log:error('Hot-desking auto log off status could not be changed from ' .. tostring(caller_phone.record.nightly_reboot) .. ' to ' .. nightly_reboot);
    return { continue = false, code = 401, phrase = 'Value could not be changed', no_cdr = true }
    
  end

  self.log:debug('Hot-desking auto log off changed from ' .. tostring(caller_phone.record.nightly_reboot) .. ' to ' .. nightly_reboot);

  caller:answer();
  caller:send_display('Logout successful');
  caller:sleep(1000);
end

function Functions.redial(self, caller)
  -- Ensure a valid sip account
  local caller_sip_account = self:ensure_caller_sip_account(caller);
  if not caller_sip_account then
    return { continue = false, code = 403, phrase = 'Incompatible caller', no_cdr = true }
  end

  local sql_query = 'SELECT `destination_number` \
    FROM `call_histories` \
    WHERE `entry_type` = "dialed" \
    AND `call_historyable_type` = "SipAccount" \
    AND `call_historyable_id` = ' .. caller_sip_account.record.id .. ' \
    ORDER BY `start_stamp` DESC LIMIT 1';

  local phone_number = self.database:query_return_value(sql_query);

  common_str = require 'common.str';
  if common_str.blank(phone_number) then
    return { continue = false, code = 404, phrase = 'No phone number saved', no_cdr = true }
  end

  return { continue = true, number = phone_number }
end

function Functions.dial_clir_off(self, caller, phone_number)
  -- Ensure a valid sip account
  local caller_sip_account = self:ensure_caller_sip_account(caller);
  if not caller_sip_account then
    return { continue = false, code = 403, phrase = 'Incompatible caller', no_cdr = true }
  end

  caller.clir = false;
  return { continue = true, number = phone_number }
end

function Functions.dial_clir_on(self, caller, phone_number)
  -- Ensure a valid sip account
  local caller_sip_account = self:ensure_caller_sip_account(caller);
  if not caller_sip_account then
    return { continue = false, code = 403, phrase = 'Incompatible caller', no_cdr = true }
  end

  caller.clir = true;
  return { continue = true, number = phone_number }
end

function Functions.callwaiting_on(self, caller)
  -- Find caller's SipAccount
  local caller_sip_account = self:ensure_caller_sip_account(caller);
  if not caller_sip_account then
    return { continue = false, code = 403, phrase = 'Incompatible caller', no_cdr = true }
  end

  local sql_query = 'UPDATE `sip_accounts` SET `call_waiting` = TRUE WHERE `id` = ' .. caller_sip_account.record.id;
  
  if not self.database:query(sql_query) then
    self.log:notice("Call Waiting could not be set");
    return { continue = false, code = 500, phrase = 'Call Waiting could not be set', no_cdr = true }
  end

  caller:answer();
  caller:send_display('Call waiting on');
  caller:sleep(1000);
  return { continue = false, code = 200, phrase = 'OK', no_cdr = true }
end

function Functions.callwaiting_off(self, caller)
  -- Find caller's SipAccount
  local caller_sip_account = self:ensure_caller_sip_account(caller);
  if not caller_sip_account then
    return { continue = false, code = 403, phrase = 'Incompatible caller', no_cdr = true }
  end

  local sql_query = 'UPDATE `sip_accounts` SET `call_waiting` = FALSE WHERE `id` = ' .. caller_sip_account.record.id;
  
  if not self.database:query(sql_query) then
    self.log:notice("Call Waiting could not be set");
    return { continue = false, code = 500, phrase = 'Call Waiting could not be set', no_cdr = true }
  end

  caller:answer();
  caller:send_display('Call waiting off');
  caller:sleep(1000);
  return { continue = false, code = 200, phrase = 'OK', no_cdr = true }
end

function Functions.clir_on(self, caller)
  -- Find caller's SipAccount
  local caller_sip_account = self:ensure_caller_sip_account(caller);
  if not caller_sip_account then
    return { continue = false, code = 403, phrase = 'Incompatible caller', no_cdr = true }
  end

  local sql_query = 'UPDATE `sip_accounts` SET `clir` = TRUE WHERE `id` = ' .. caller_sip_account.record.id;
  
  if not self.database:query(sql_query) then
    self.log:notice("CLIR could not be set");
    return { continue = false, code = 500, phrase = 'CLIR could not be set', no_cdr = true }
    
  end

  caller:answer();
  caller:send_display('CLIR on');
  caller:sleep(1000);
  return { continue = false, code = 200, phrase = 'OK', no_cdr = true }
end

function Functions.clir_off(self, caller)
  -- Find caller's SipAccount
  local caller_sip_account = self:ensure_caller_sip_account(caller);
  if not caller_sip_account then
    return { continue = false, code = 403, phrase = 'Incompatible caller', no_cdr = true }
  end

  local sql_query = 'UPDATE `sip_accounts` SET `clir` = FALSE WHERE `id` = ' .. caller_sip_account.record.id;
  
  if not self.database:query(sql_query) then
    self.log:notice("CLIR could not be set");
    return { continue = false, code = 500, phrase = 'CLIR could not be set', no_cdr = true }
    
  end

  caller:answer();
  caller:send_display('CLIR off');
  caller:sleep(1000);
  return { continue = false, code = 200, phrase = 'OK', no_cdr = true }
end

function Functions.clip_on(self, caller)
  -- Find caller's SipAccount
  local caller_sip_account = self:ensure_caller_sip_account(caller);
  if not caller_sip_account then
    return { continue = false, code = 403, phrase = 'Incompatible caller', no_cdr = true }
  end

  local sql_query = 'UPDATE `sip_accounts` SET `clip` = TRUE WHERE `id` = ' .. caller_sip_account.record.id;
  
  if not self.database:query(sql_query) then
    self.log:notice("CLIP could not be set");
    return { continue = false, code = 500, phrase = 'CLIP could not be set', no_cdr = true }
    
  end

  caller:answer();
  caller:send_display('CLIP on');
  caller:sleep(1000);
  return { continue = false, code = 200, phrase = 'OK', no_cdr = true }
end


function Functions.clip_off(self, caller)
  -- Find caller's SipAccount
  local caller_sip_account = self:ensure_caller_sip_account(caller);
  if not caller_sip_account then
    return { continue = false, code = 403, phrase = 'Incompatible caller', no_cdr = true }
  end

  local sql_query = 'UPDATE `sip_accounts` SET `clip` = FALSE WHERE `id` = ' .. caller_sip_account.record.id;
  
  if not self.database:query(sql_query) then
    self.log:notice("CLIP could not be set");
    return { continue = false, code = 500, phrase = 'CLIP could not be set', no_cdr = true }
    
  end

  caller:answer();
  caller:send_display('CLIP off');
  caller:sleep(1000);
  return { continue = false, code = 200, phrase = 'OK', no_cdr = true }
end

function Functions.call_forwarding_off(self, caller, call_forwarding_service, delete)
  -- Find caller's SipAccount
  local caller_sip_account = self:ensure_caller_sip_account(caller);
  if not caller_sip_account then
    return { continue = false, code = 403, phrase = 'Incompatible caller', no_cdr = true }
  end

  caller_sip_account.domain = caller_sip_account.domain or caller.domain;

  if not caller_sip_account:call_forwarding_off(call_forwarding_service, nil, delete) then
    self.log:notice('FUNCTION_CALL_FORWARDING_OFF - call forwarding could not be deactivated');
    return { continue = false, code = 500, phrase = 'Call Forwarding could not be deactivated', no_cdr = true }
  end

  caller:answer();
  caller:send_display('Call forwarding off');
  caller:sleep(1000);
  return { continue = false, code = 200, phrase = 'OK', no_cdr = true }
end


function Functions.call_forwarding_on(self, caller, call_forwarding_service, destination, destination_type, timeout)
  if not call_forwarding_service then
    self.log:notice('FUNCTION_CALL_FORWARDING_ON - no call forwarding service specified');
  end

  -- Find caller's SipAccount
  local caller_sip_account = self:ensure_caller_sip_account(caller);
  if not caller_sip_account then
    return { continue = false, code = 403, phrase = 'Incompatible caller', no_cdr = true }
  end

  caller_sip_account.domain = caller_sip_account.domain or caller.domain;

  if not caller_sip_account:call_forwarding_on(call_forwarding_service, destination, destination_type, timeout) then
    self.log:notice('FUNCTION_CALL_FORWARDING_ON - call forwarding could not be activated');
    return { continue = false, code = 500, phrase = 'Call Forwarding could not be activated', no_cdr = true }
  end

  caller:answer();
  caller:send_display('Call forwarding on');
  caller:sleep(1000);
  return { continue = false, code = 200, phrase = 'OK', no_cdr = true }
end


function Functions.call_forwarding_toggle(self, caller, call_forwarding_service, phone_number_id)
  local defaults = {log = self.log, database = self.database, domain = caller.domain}

  -- Find caller's SipAccount
  local caller_sip_account = self:ensure_caller_sip_account(caller);
  if not caller_sip_account then
    return { continue = false, code = 403, phrase = 'Incompatible caller', no_cdr = true }
  end

  require "common.phone_number"
  local phone_number_class = common.phone_number.PhoneNumber:new{ log = self.log, database = self.database, domain = caller.domain };
  local phone_numbers = phone_number_class:list_by_owner(caller_sip_account.record.id, 'SipAccount');

  local result = nil;
  for index, phone_number in pairs(phone_numbers) do
    phone_number_object = phone_number_class:find_by_number(phone_number);
    if phone_number_object then
      if not result then
        result = phone_number_object:call_forwarding_toggle(call_forwarding_service);
      elseif result.active then
        phone_number_object:call_forwarding_on(call_forwarding_service, result.destination, result.destination_type, result.timeout);
      else
        phone_number_object:call_forwarding_off(call_forwarding_service);
      end      
    end
  end

  if not result then
    self.log:notice("call forwarding could not be toggled");
    return { continue = false, code = 500, phrase = 'Call Forwarding could not be toggled', no_cdr = true }
    
  end

  caller:answer();
  caller:send_display('Call forwarding toggled');
  caller:sleep(1000);
  return { continue = false, code = 200, phrase = 'OK', no_cdr = true }
end


function Functions.voicemail_message_leave(self, caller, phone_number)
  require 'dialplan.voicemail'
  local voicemail_account = dialplan.voicemail.Voicemail:new{ log = self.log, database = self.database }:find_by_number(phone_number);

  if not voicemail_account then
    return { continue = false, code = 404, phrase = 'Mailbox not found', no_cdr = true }
  end

  voicemail_account:leave(caller, phone_number);

  if caller:to_s("voicemail_message_len") ~= '' then
    voicemail_account:send_notify(caller);
  else
    self.log:debug("voicemail - no message saved");
  end

  return { continue = false, code = 200, phrase = 'OK' }
end


function Functions.voicemail_check(self, caller, phone_number)
  local voicemail_account = nil;
  local voicemail_authorized = false;

  require 'dialplan.voicemail'

  if phone_number then
    voicemail_account = dialplan.voicemail.Voicemail:new{ log = self.log, database = self.database }:find_by_number(phone_number);
  else
    if caller.auth_account_type == 'SipAccount' then
      voicemail_account = dialplan.voicemail.Voicemail:new{ log = self.log, database = self.database }:find_by_sip_account_id(caller.auth_account.id);
      voicemail_authorized = true;
    end
  end

  if not voicemail_account then
    return { continue = false, code = 404, phrase = 'Mailbox not found', no_cdr = true }
  end

  voicemail_account:menu(caller, voicemail_authorized);

  return { continue = false, code = 200, phrase = 'OK', no_cdr = true }
end


function Functions.acd_membership_toggle(self, caller, agent_id, phone_number)
  -- Find caller's SipAccount
  local caller_sip_account = self:ensure_caller_sip_account(caller);
  if not caller_sip_account then
    return { continue = false, code = 403, phrase = 'Incompatible caller', no_cdr = true }
  end

  require 'dialplan.acd'
  local acd_class = dialplan.acd.AutomaticCallDistributor:new{ log = self.log, database = self.database, domain = self.domain };

  self.log:info('ACD_MEMBERSHIP_TOGGLE - sipaccount=', caller_sip_account.id, '/', caller_sip_account.uuid, ', agent=', agent_id, ', ACD phone number: ', phone_number);

  if not tonumber(agent_id) or tonumber(agent_id) == 0 then

    if not phone_number then
      self.log:notice('ACD_MEMBERSHIP_TOGGLE - neither agent_id nor phone_number specified');
      return { continue = false, code = 404, phrase = 'Agent not found', no_cdr = true }
    end

    require "common.phone_number"
    local phone_number_object = common.phone_number.PhoneNumber:new{ log = self.log, database = self.database, domain = caller.domain }:find_by_number(phone_number, {'AutomaticCallDistributor'});

    if not phone_number_object or not tonumber(phone_number_object.record.phone_numberable_id) then
      self.log:notice('ACD_MEMBERSHIP_TOGGLE - ACD not found');
      return { continue = false, code = 404, phrase = 'ACD not found', no_cdr = true }
    end

    local agent = acd_class:agent_find_by_acd_and_destination(phone_number_object.record.phone_numberable_id, caller_sip_account.class, caller_sip_account.id);

    if not agent or not tonumber(agent.id) then
      self.log:notice('ACD_MEMBERSHIP_TOGGLE - agent not found');
      return { continue = false, code = 404, phrase = 'Agent not found', no_cdr = true }
    end

    agent_id = agent.id;
  end

  local status = acd_class:agent_status_toggle(agent_id, 'sipaccount', caller_sip_account.id);

  if not status then
    self.log:error('ACD_MEMBERSHIP_TOGGLE - error toggling ACD membership');
    return { continue = false, code = 500, phrase = 'Error toggling ACD membership', no_cdr = true }
  end

  self.log:info('ACD_MEMBERSHIP_TOGGLE - sipaccount=', caller_sip_account.id, '/', caller_sip_account.uuid, ', agent=', agent_id, ', status: ', status);

  caller:answer();
  caller:send_display('ACD membership toggled: ' .. status);
  caller:sleep(500);
  caller.session:sayPhrase('acd_agent_status', tostring(status));
  return { continue = false, code = 200, phrase = 'OK', no_cdr = true }
end


function Functions.hangup(self, caller, code, phrase)
  if not tonumber(code) then
    code = 403;
    phrase = 'Forbidden';
  end

  if common.str.blank(phrase) then
    phrase = 'Hangup here';
  end

  self.log:info("FUNCTION_HANGUP code: ", code, ', phrase: ', phrase);
  return { continue = false, code = code, phrase = phrase:gsub('_', ' '), no_cdr = true }
end


function Functions.call_parking_inout(self, caller, stall_name, lot_name)
  require 'dialplan.call_parking';
  local parking_stall = dialplan.call_parking.CallParking:new{ log = self.log, database = self.database, caller = caller }:find_by_name(stall_name);
  
  if not parking_stall then
    return { continue = false, code = 404, phrase = 'Parking stall not found', no_cdr = true }
  end

  if lot_name and parking_stall.lot ~= lot_name then
    return { continue = false, code = 404, phrase = 'Parking lot not found', no_cdr = true }
  end

  parking_stall:park_retrieve();

  return { continue = false, code = 200, phrase = 'OK', no_cdr = true }
end


function Functions.call_parking_inout_index(self, caller, stall_index)
  if not tonumber(stall_index) then
    self.log:notice('FUNCTION_CALL_PARKING_INOUT_INDEX - malformed index: ', stall_index);
    return { continue = false, code = 404, phrase = 'No parkings stall specified', no_cdr = true }
  end

  local owner = common.array.try(caller, 'auth_account.owner');
  
  if not owner then
    self.log:notice('FUNCTION_CALL_PARKING_INOUT_INDEX - stall owner not specified');
    return { continue = false, code = 404, phrase = 'No parkings stalls owner' , no_cdr = true }
  end

  require 'dialplan.call_parking';
  local parking_stalls = dialplan.call_parking.CallParking:new{ log = self.log, database = self.database, caller = caller }:find_by_owner(owner.id, owner.class);

  if not parking_stalls or #parking_stalls < 1 then
    self.log:notice('FUNCTION_CALL_PARKING_INOUT_INDEX - no parkings stalls found');
    return { continue = false, code = 404, phrase = 'No parkings stalls', no_cdr = true }
  end

  local parking_stall = parking_stalls[tonumber(stall_index)];

  if not parking_stall then
    self.log:notice('FUNCTION_CALL_PARKING_INOUT_INDEX - no parkings stall found with index: ', stall_index);
    return { continue = false, code = 404, phrase = 'Parking stall not found', no_cdr = true }
  end

  self.log:info('FUNCTION_CALL_PARKING_INOUT_INDEX parking/retrieving call - parkingstall=', parking_stall.id, '/', parking_stall.name, ', index: ', stall_index);
  parking_stall:park_retrieve();

  return { continue = false, code = 200, phrase = 'OK', no_cdr = true }
end
