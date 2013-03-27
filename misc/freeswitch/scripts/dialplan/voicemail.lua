-- Gemeinschaft 5 module: voicemail class
-- (c) AMOOMA GmbH 2013
-- 

module(...,package.seeall)

Voicemail = {}

DEFAULT_SETTINGS = {
  pin_length_max = 10,
  pin_length_min = 2,
  pin_timeout = 20,
  key_new_messages = '1',
  key_saved_messages = '2',
  key_config_menu = '0',
  key_terminator = '#',
  key_previous = '4',
  key_next = '6',
  key_delete = '7',
  key_save = '2',
  key_main_menu = '#',
  record_length_max = 300,
  record_length_min = 4,
  records_max = 100,
  silence_lenght_abort = 3,
  silence_level = 500,
  beep = 'tone_stream://%(1000,0,500)',
  record_file_prefix = 'voicemail_',
  record_file_suffix = '.wav',
  record_file_path = '/var/spool/freeswitch/',
  record_repeat = 3,
  notify = true,
  attachment = true,
  mark_read = true,
  purge = false, 
}

-- create voicemail object
function Voicemail.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.class = 'voicemail';
  self.log = arg.log;
  self.database = arg.database;
  self.record = arg.record;
  self.domain = arg.domain;
  return object
end


function Voicemail.find_by_sql(self, sql_query)
  local voicemail_account = nil;
  self.database:query(sql_query, function(entry)
    voicemail_account = Voicemail:new(self);
    voicemail_account.record = entry;
    voicemail_account.id = tonumber(entry.id);
    voicemail_account.uuid = entry.uuid;
    voicemail_account.name = entry.name;
    voicemail_account.settings = self:settings_get(entry.id);
  end);

  return voicemail_account;
end


function Voicemail.find_by_name(self, name)
  local sql_query = 'SELECT * FROM `voicemail_accounts` \
    WHERE `name` = ' .. self.database:escape(name, '"') .. ' LIMIT 1';

  return self:find_by_sql(sql_query);
end


function Voicemail.find_by_id(self, id)
   local sql_query = 'SELECT * FROM `voicemail_accounts` \
    WHERE `id` = ' .. self.database:escape(id, '"') .. ' LIMIT 1';

  return self:find_by_sql(sql_query);
end


function Voicemail.find_by_sip_account_id(self, id)
   local sql_query = 'SELECT `a`.* FROM `voicemail_accounts` `a` \
    JOIN `sip_accounts` `b` ON `a`.`id` = `b`.`voicemail_account_id` \
    WHERE `b`.`id` = ' .. self.database:escape(id, '"') .. ' LIMIT 1';

  return self:find_by_sql(sql_query);
end


function Voicemail.find_by_number(self, number)
   local sql_query = 'SELECT `a`.* FROM `voicemail_accounts` `a` \
    JOIN `sip_accounts` `b` ON `a`.`id` = `b`.`voicemail_account_id` \
    JOIN `phone_numbers` `c` ON `b`.`id` = `c`.`phone_numberable_id` \
    WHERE `c`.`number` = ' .. self.database:escape(number, '"') .. ' \
    AND `c`.`phone_numberable_type` = "SipAccount" LIMIT 1';

  return self:find_by_sql(sql_query);
end


function Voicemail.settings_get(self, id)
  require 'common.configuration_table';
  local parameters = common.configuration_table.get(self.database, 'voicemail', 'settings', { settings = DEFAULT_SETTINGS });

  return common.configuration_table.settings(self.database, 'voicemail_settings', 'voicemail_account_id', id or self.id, parameters)
end


function Voicemail.messages_get(self, status)
  local sql_query = 'SELECT * FROM `voicemail_msgs` WHERE `username` = ' .. self.database:escape(self.name, '"');

  status = status or 'all';

  if status == 'read' then
    sql_query = sql_query .. ' AND `read_epoch` > 0';
  elseif status == 'unread' then
    sql_query = sql_query .. ' AND (`read_epoch` = 0 OR `read_epoch` IS NULL)';
  elseif status == 'new' then
    sql_query = sql_query .. ' AND `in_folder` != "save" AND `flags` != "save"';
  elseif status == 'saved' then
    sql_query = sql_query .. ' AND (`in_folder` = "save" OR `flags` = "save")';
  end

  return self.database:query_return_all(sql_query);
end


function Voicemail.check_pin(self, pin)
  self.caller:answer();
  self.caller:sleep(1000);

  require 'dialplan.ivr';
  local ivr = dialplan.ivr.Ivr:new{ caller = self.caller, log = self.log };

  local digits = '';
  for i = 1, 3 do
    if digits == pin then
      self.caller:send_display('PIN: OK');
      break
    elseif digits ~= "" then
      self.caller:send_display('PIN: wrong');
    end
    self.caller:send_display('Enter PIN');
    digits = ivr:read_phrase('voicemail_enter_pass', nil, self.settings.pin_length_min, self.settings.pin_length_max, self.settings.pin_timeout, self.settings.terminator_key);
  end

  if digits ~= pin then
    return false
  end

  return true;
end


function Voicemail.menu_main(self, caller, authorized)
  self.caller = caller;
  
  require 'dialplan.ivr';
  self.ivr = dialplan.ivr.Ivr:new{ caller = self.caller, log = self.log };

  if not authorized then
    if common.str.blank(self.pin) then
      self.log:notice('VOICEMAIL_MAIN_MENU - unaunthorized, no PIN, ', self.class, '=', self.id, '/', self.uuid, '|', self.name);
      return { continue = false, code = 500, phrase = 'Unauthorized', no_cdr = true }
    end

    self.caller:answer();
    self.caller:sleep(1000);

    if not self.ivr:check_pin('voicemail_enter_pass', 'voicemail_fail_auth', self.pin) then
      self.log:notice('VOICEMAIL_MAIN_MENU - wrong PIN, ', self.class, '=', self.id, '/', self.uuid, '|', self.name);
      caller.session:sayPhrase('voicemail_goodbye');
      return { continue = false, code = 500, phrase = 'Unauthorized', no_cdr = true }
    end
  end

  local messages_new = self:messages_get('unread');
  local messages_saved = self:messages_get('read');

  if not caller:answered() then
    self.caller:answer();
    self.caller:sleep(1000);
  end

  if self.settings.voicemail_hello then
    caller.session:sayPhrase('voicemail_hello');
  end

  if self.settings.voicemail_message_count then
    caller.session:sayPhrase('voicemail_message_count', #messages_new .. ':new');
  end

  while true do
    self.log:info('VOICEMAIL_MAIN_MENU - ', self.class, '=', self.id, '/', self.uuid, '|', self.name,  ', messages: ', #messages_new, ':', #messages_saved);
    self.caller:send_display(#messages_new .. ' new messages');

    local main_menu = {
      { key = self.settings.key_new_messages, method = self.menu_messages, parameters = { self, 'new', messages_new } },
      { key = self.settings.key_saved_messages, method = self.menu_messages, parameters = { self, 'saved', messages_saved } },
      { key = self.settings.key_config_menu, method = self.menu_options, parameters = { self } },
      { key = self.settings.key_terminator, exit = true },
      { key = '', exit = true },
    };
    
    local digits, key = self.ivr:ivr_phrase('voicemail_menu', main_menu);
    self.log:debug('VOICEMAIL_MAIN_MENU - digit: ', digits);
    if key.exit then
      break;
    end

    key.method(unpack(key.parameters));
    
    messages_new = self:messages_get('unread');
    messages_saved = self:messages_get('read');
  end
  self.caller:send_display('Goodbye');
  caller.session:sayPhrase('voicemail_goodbye');
end


function Voicemail.menu_messages(self, folder, messages)
  self.log:info('VOICEMAIL_MESSAGES_MENU - ', folder,' messages: ', #messages);
  
  local digits = nil;
  local key = nil;

  local message_menu = {
    { key = self.settings.key_previous, action = 'previous' },
    { key = self.settings.key_delete, action = 'delete' },
    { key = self.settings.key_save, action = 'save' },
    { key = self.settings.key_next, action = 'next' },
    { key = self.settings.key_main_menu, exit = true },
  };
  
  if folder == 'saved' then
    message_menu = {
      { key = self.settings.key_previous, action = 'previous' },
      { key = self.settings.key_delete, action = 'delete' },
      { key = self.settings.key_next, action = 'next' },
      { key = self.settings.key_main_menu, exit = true },
    };
  end

  if #messages == 0 then
    digits, key = self.ivr:ivr_phrase('voicemail_no_messages', message_menu, 0, 0);
    return;
  end

  local index = 1;
  while index <= #messages do
    local message = messages[index];
    self.caller:send_display(index .. ': ' .. message.cid_name .. ' ' .. message.cid_number);
    digits, key = self.ivr:ivr_phrase('voicemail_message_play', message_menu, 0, 0, 
      index .. ':' .. message.created_epoch .. ':' .. message.file_path
    );
    if digits == '' then
      if common.str.to_i(message.read_epoch) == 0 then
        self:message_mark_read(message);
      end
      digits, key = self.ivr:ivr_phrase('voicemail_message_menu_' .. folder, message_menu, 15, 0);
    end

    if not key or key.exit then
      break;
    end

    if key.action == 'previous' then
      if index > 1 then
        index = index - 1;
      end
    else
      index = index + 1;
    end

    if key.action == 'delete' and self:message_delete(message) then
      self.caller:send_display('Message deleted');
      digits = self.caller.session:sayPhrase('voicemail_ack', 'deleted');
    elseif key.action == 'save' and self:message_save(message) then
      self.caller:send_display('Message saved');
      digits = self.caller.session:sayPhrase('voicemail_ack', 'saved');
    end
    if index > #messages then
      digits = self.ivr:ivr_phrase('voicemail_no_messages', message_menu, 0, 0);
    end
  end
end


function Voicemail.menu_options(self)
  self.log:info('VOICEMAIL_OPTIONS_MENU');
  self.caller:send_display('Voicemail options');
end


function Voicemail.message_delete(self, message)
  self.log:debug('VOICEMAIL_MESSAGE_DELETE - message: ', message.uuid);
  require 'common.fapi';
  return common.fapi.FApi:new{ log = self.log }:execute('vm_delete', message.username .. '@' .. message.domain .. ' ' .. message.uuid);
end

function Voicemail.message_mark_read(self, message)
  self.log:debug('VOICEMAIL_MESSAGE_MARK_READ - message: ', message.uuid);
  require 'common.fapi';
  return common.fapi.FApi:new{ log = self.log }:execute('vm_read', message.username .. '@' .. message.domain .. ' read ' .. message.uuid);
end


function Voicemail.message_save(self, message)
  self.log:debug('VOICEMAIL_MESSAGE_SAVE - message: ', message.uuid);
  require 'common.fapi';
  return common.fapi.FApi:new{ log = self.log }:execute('vm_fsdb_msg_save', 'default ' .. message.domain .. ' ' .. message.username .. ' ' .. message.uuid);
end


function Voicemail.leave(self, caller, greeting)
  local forwarding_number = caller.forwarding_number;
  self.log:info('VOICEMAIL_LEAVE - voicemail_account=', self.record.id, '/', self.record.uuid, '|', self.record.name, ', forwarding_number: ', forwarding_number);

  caller:set_callee_id(forwarding_number, common.array.try(caller, 'auth_account.caller_name') or common.array.try(caller, 'auth_account.name'));
  caller:answer();
  caller:send_display(common.array.try(caller, 'auth_account.caller_name') or common.array.try(caller, 'auth_account.name'));
  caller:sleep(1000);

  if not common.str.blank(forwarding_number) then
    caller.session:sayPhrase('voicemail_play_greeting', (tostring(forwarding_number):gsub('[%D]', '')));
  end

  local record_file_name = self.settings.record_file_path ..self.settings.record_file_prefix .. caller.uuid .. self.settings.record_file_suffix;
  self.log:info('VOICEMAIL_LEAVE - recording to file: ', tostring(record_file_name));
  
  require 'dialplan.ivr';
  local ivr = dialplan.ivr.Ivr:new{ caller = caller, log = self.log };

  local duration = ivr:record(
    record_file_name, 
    'voicemail_record_message', 
    'voicemail_message_too_short', 
    self.settings.record_length_max, 
    self.settings.record_length_min, 
    self.settings.record_repeat, 
    self.settings.silence_level,
    self.settings.silence_lenght_abort);

  if duration >= self.settings.record_length_min then   
    self.log:info('VOICEMAIL_LEAVE - saving recorded message to voicemail, duration: ', duration);
    require 'common.fapi'
    common.fapi.FApi:new{ log = self.log, uuid = caller.uuid }:execute('vm_inject', 
      self.record.name .. 
      '@' .. self.domain .. " '" .. 
      record_file_name .. "' '" .. 
      caller.caller_id_number .. "' '" .. 
      caller.caller_id_name .. "' '" ..
      caller.uuid .. "'"
    );
    caller:set_variable('voicemail_message_len', duration);
    self:trigger_notification(caller);
  else
    caller:set_variable('voicemail_message_len');
  end 
  os.remove(record_file_name);
  caller:send_display('Goodbye');
  caller.session:sayPhrase('voicemail_goodbye');
end


function Voicemail.trigger_notification(self, caller)
  local command = 'http_request.lua ' .. caller.uuid .. ' http://127.0.0.1/trigger/voicemail?voicemail_account_id=' .. tostring(self.id);

  require 'common.fapi';
  return common.fapi.FApi:new():execute('luarun', command);
end
