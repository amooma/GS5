-- Gemeinschaft 5 module: voicemail class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

Voicemail = {}

MESSAGE_LENGTH_MIN = 3;
MESSAGE_LENGTH_MAX = 120;
SILENCE_LENGTH_ABORT = 5;
SILENCE_LEVEL = 500;
BEEP = 'tone_stream://%(1000,0,500)';
RECORD_FILE_PREFIX = '/tmp/voicemail_';

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
  return object
end

-- find voicemail account by sip account id
function Voicemail.find_by_sip_account_id(self, id)
  local sql_query = 'SELECT `a`.`id`, `a`.`uuid`, `a`.`auth_name`, `a`.`caller_name`, `b`.`name_path`, `b`.`greeting_path`, `a`.`voicemail_pin`, `b`.`password`, `c`.`host` AS `domain` \
    FROM `sip_accounts` `a` LEFT JOIN `voicemail_prefs` `b` ON `a`.`auth_name` = `b`.`username` \
    JOIN `sip_domains` `c` ON `a`.`sip_domain_id` = `c`.`id` \
    WHERE `a`.`id` = ' .. tonumber(id);

  local voicemail_account = nil;
  self.database:query(sql_query, function(entry)
    voicemail_account = Voicemail:new(self);
    voicemail_account.record = entry;
    voicemail_account.id = tonumber(entry.id);
    voicemail_account.uuid = entry.uuid;
  end)

  return voicemail_account;
end

-- Find Voicemail account by name
function Voicemail.find_by_name(self, account_name)
  id = tonumber(id) or 0;
  local sql_query = string.format('SELECT * FROM `voicemail_prefs` WHERE `username`= "%s" LIMIT 1', account_name)
  local record = nil

  self.database:query(sql_query, function(voicemail_entry)
    record = voicemail_entry
  end)

  if voicemail_account then
    voicemail_account.account_name = account_name;
    if record then
      voicemail_account.name_path = record.name_path;
      voicemail_account.greeting_path = record.greeting_path;
      voicemail_account.password = record.password;
    end
  end

  return voicemail_account
end

-- Find Voicemail account by name
function Voicemail.find_by_number(self, phone_number)
  local sip_account = nil;

  require "common.phone_number"
  local phone_number_class = common.phone_number.PhoneNumber:new{ log = self.log, database = self.database };
  local destination_number_object = phone_number_class:find_by_number(phone_number);
  if destination_number_object and destination_number_object.record.phone_numberable_type == "SipAccount" then
    return Voicemail:find_by_sip_account_id(destination_number_object.record.phone_numberable_id);
  end

  return false;
end


function Voicemail.leave(self, caller, phone_number)
  require 'common.str'

  self.log:info('VOICEMAIL_LEAVE - account=', self.record.id, '/', self.record.uuid, ', auth_name: ', self.record.auth_name, ', caller_name: ', self.record.caller_name);

  caller:set_callee_id(phone_number, self.record.caller_name);
  caller:answer();
  caller:send_display(common.str.to_s(self.record.caller_name), common.str.to_s(phone_number));
  caller:sleep(1000);

  if not common.str.blank(self.record.greeting_path) then
    caller.session:sayPhrase('voicemail_play_greeting', 'greeting:' .. tostring(self.record.greeting_path));
  elseif not common.str.blank(self.record.name_path) then
    caller.session:sayPhrase('voicemail_play_greeting', 'name:' .. tostring(self.record.name_path));
  elseif not common.str.blank(phone_number) then
    caller.session:sayPhrase('voicemail_play_greeting', (tostring(phone_number):gsub('[%D]', '')));
  end

  local record_file_name = RECORD_FILE_PREFIX .. caller.uuid .. '.wav';
  caller.session:streamFile(BEEP);
  self.log:info('VOICEMAIL_LEAVE - recording to file: ', tostring(record_file_name));
  local result = caller.session:recordFile(record_file_name, MESSAGE_LENGTH_MAX, SILENCE_LEVEL, SILENCE_LENGTH_ABORT);
  local duration = caller:to_i('record_seconds');

  if duration >= MESSAGE_LENGTH_MIN then   
    self.log:info('VOICEMAIL_LEAVE - saving recorded message to voicemail, duration: ', duration);
    require 'common.fapi'
    common.fapi.FApi:new{ log = self.log, uuid = caller.uuid }:execute('vm_inject', 
      self.record.auth_name .. 
      '@' .. self.record.domain .. " '" .. 
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
  return true;
end


function Voicemail.trigger_notification(self, caller)
  local command = 'http_request.lua ' .. caller.uuid .. ' http://127.0.0.1/trigger/voicemail?sip_account_id=' .. tostring(self.id);

  require 'common.fapi'
  return common.fapi.FApi:new():execute('luarun', command);
end


function Voicemail.menu(self, caller, authorized)
  self.log:info('VOICEMAIL_MENU - account: ', self.record.auth_name);

  if authorized then
    caller:set_variable('voicemail_authorized', true);
  end

  caller:set_callee_id(phone_number, self.record.caller_name);
  caller:answer();
  caller:send_display(common.str.to_s(self.record.caller_name), common.str.to_s(phone_number));

  caller:sleep(1000);
  caller:set_variable('skip_greeting', true);
  caller:set_variable('skip_instructions', true);
  
  caller:execute('voicemail', 'check default ' .. self.record.domain .. ' ' .. self.record.auth_name);
end
