-- Gemeinschaft 5 module: conference class
-- (c) AMOOMA GmbH 2013
-- 

module(...,package.seeall)

Conference = {}

-- create conference object
function Conference.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.class = 'conference';
  self.log = arg.log;
  self.database = arg.database;
  self.record = arg.record;
  return object;
end


function Conference.settings_get(self)
  require 'common.array';
  require 'common.configuration_table';

  local configuration = common.configuration_table.get(self.database, 'conferences');
  if not configuration then
    return nil;
  end

  local parameters = configuration.parameters or {};
  local settings = configuration.settings or {};
  local sounds = configuration.sounds or {};

  settings.members_max = settings.members_max or tonumber(parameters['max-members']) or 100;
  settings.pin_length_max = tonumber(settings.pin_length_max) or 10;
  settings.pin_length_min = tonumber(settings.pin_length_min) or 2;
  settings.pin_timeout = tonumber(settings.pin_timeout) or 4000;
  settings.announcement_max_length = tonumber(settings.announcement_max_length) or 10;
  settings.announcement_silence_threshold = tonumber(settings.announcement_silence_threshold) or 500;
  settings.announcement_silence_length = tonumber(settings.announcement_silence_length) or 3;
  settings.flags = settings.flags or { waste = true };
  sounds.pin = sounds.pin or 'conference/conf-pin.wav';
  sounds.has_joined = sounds.has_joined or 'conference/conf-has_joined.wav';
  sounds.has_left = sounds.has_left or 'conference/conf-has_left.wav';
  sounds.alone = sounds.has_alone or 'conference/conf-alone.wav';

  settings.key_enter = parameters.key_enter or '#';
  settings.spool_dir = settings.spool_dir or '/var/spool/freeswitch';
  return settings, sounds;
end


function Conference.find_by_id(self, id)
  local sql_query = 'SELECT *, (NOW() >= `start` AND NOW() <= `end`) AS `open_now` FROM `conferences` WHERE `id`= ' .. tonumber(id) .. '  LIMIT 1';
  local conference = nil;

  self.database:query(sql_query, function(conference_entry)
    conference = Conference:new(self);
    conference.record = conference_entry;
    conference.id = tonumber(conference_entry.id);
    conference.identifier = 'conference' .. conference.id;
    conference.uuid = conference_entry.uuid;
    conference.pin = conference_entry.pin;
    conference.open_for_public = common.str.to_b(conference_entry.open_for_anybody);
    conference.announce_entering = common.str.to_b(conference_entry.announce_new_member_by_name);
    conference.announce_leaving = common.str.to_b(conference_entry.announce_left_member_by_name);
    if not common.str.blank(conference_entry.open_now) then
      conference.open_now = common.str.to_b(conference_entry.open_now);
    end

    conference.settings, conference.sounds = self:settings_get();
    if conference.settings then
      conference.settings.members_max = tonumber(conference.record.max_members) or conference.settings.members_max;
    else
      conference.log:error('CONFERENCE - no basic configuration');
    end
  end)
  
  return conference; 
end


function Conference.find_invitee_by_numbers(self, phone_numbers)
  if not self.record then 
    return false;
  end

  local sql_query = 'SELECT `a`.* \
    FROM `conference_invitees` `a` \
    JOIN `phone_numbers` `b` ON `b`.`phone_numberable_id` = `a`.`id` \
    WHERE `b`.`phone_numberable_type` = "ConferenceInvitee" \
    AND `a`.`conference_id` = ' .. self.id .. ' \
    AND `b`.`number` IN ("' .. table.concat(phone_numbers, "','") .. '") \
    LIMIT 1';
  
  local invitee = nil;

  self.database:query(sql_query, function(invitee_entry)
    invitee = invitee_entry;
  end)

  return invitee;
end


function Conference.members_count(self)
  return tonumber(self.caller:result('conference ' .. self.identifier .. ' list count')) or 0;
end


function Conference.check_pin(self, pin)
  local digits = '';
  for i = 1, 3 do
    if digits == pin then
      self.caller:send_display('PIN: OK');
      break
    elseif digits ~= "" then
      self.caller:send_display('PIN: wrong');
      self.caller.session:sayPhrase('conference_bad_pin');
    end
    self.caller:send_display('Enter PIN');
    digits = self.caller.session:read(self.settings.pin_length_min, self.settings.pin_length_max, self.sounds.pin, self.settings.pin_timeout, self.settings.key_enter);
  end

  if digits ~= pin then
    return false
  end

  return true;
end


function Conference.check_ownership(self, check_caller)
  local owner = nil;

  if check_caller then
    owner = common.array.try(self.caller, 'account.owner');
  else
    owner = common.array.try(self.caller, 'auth_account.owner');
  end
  if not owner then
    return false;
  end

  if tonumber(self.record.conferenceable_id) == owner.id and self.record.conferenceable_type:lower() == owner.class then
    return true;
  end
end


function Conference.account_name_file(self)
  if not self.caller.account or tostring(self.caller.account.class):lower() ~= 'sipaccount' then
    return;
  end

  require 'dialplan.voicemail'
  local voicemail_account = dialplan.voicemail.Voicemail:new{ log = self.log, database = self.database }:find_by_sip_account_id(self.caller.account.id);
  if voicemail_account and not common.str.blank(voicemail_account.record.name_path) then
    self.log:debug('CONFERENCE ', self.id, ' - caller_name_file: ', voicemail_account.record.name_path);
    return voicemail_account.record.name_path;
  end
end


function Conference.record_name(self)
  self.caller:send_display('Record name');
  local name_file = self.settings.spool_dir .. '/conference_caller_name_' .. self.caller.uuid .. '.wav';
  self.caller.session:sayPhrase('conference_record_name');
  self.caller.session:recordFile(name_file, self.settings.announcement_max_length, self.settings.announcement_silence_threshold, self.settings.announcement_max_length);
  self.caller:send_display('Playback name');
  self.caller:playback(name_file);

  return name_file;
end


function Conference.playback(self, ...)
  local sound_files = {...};
  for index=1, #sound_files do
    self.caller:execute('set',"result=${conference(" .. self.identifier .. " play ".. tostring(sound_files[index]) .. ")}");
  end
end

function Conference.phrase(self, phrase, file_name)
  self.caller:execute('set',"result=${conference(" .. self.identifier .. " phrase ".. phrase .. ':' .. file_name .. ")}");
end

function Conference.enter(self, caller, domain)
  self.caller = caller;
  local members = self:members_count();

  self.log:info('CONFERENCE ', self.id, ' - open_for_public: ', self.open_for_public, ', open_now: ', self.open_now, ', members: ', members, ', members_max: ', self.settings.members_max);

  if self.open_now == false then
    self.log:notice('CONFERENCE ', self.id, ' - currently closed, start: ', self.record.start, ', end: ', self.record['end']);
    return { continue = false, code = 493, phrase = 'Conference closed' };
  end

  if members >= self.settings.members_max then
    self.log:notice('CONFERENCE ', self.id, ' - full, members: ', members, ', members_max: ', self.settings.members_max);
    return { continue = false, code = 493, phrase = 'Conference closed' };
  end

  local invitee = self:find_invitee_by_numbers(caller.caller_phone_numbers);
  if invitee then
    if common.str.to_b(invitee.speaker) then
      self.settings.flags.mute = nil;
    end
    if common.str.to_b(invitee.moderator) then
      self.settings.flags.moderator = true;
    end
    self.log:info('CONFERENCE ', self.id, ' - invitee=', invitee.id, '/', invitee.uuid, ', speaker: ', not self.settings.flags.mute, ', moderator: ', self.settings.flags.moderator);
    self.pin = invitee.pin;
  elseif self:check_ownership() then
    self.pin = nil;
    local caller_owner = false;
    if self:check_ownership(true) then
      self.settings.flags.moderator = true;
      self.settings.flags.dtmf = true;
      caller_owner = true;
    end
    self.log:info('CONFERENCE ', self.id, ' - owner authenticated: ', self.caller.auth_account.owner.class,'=', self.caller.auth_account.owner.id, '/', self.caller.auth_account.owner.uuid, ', owner: ', caller_owner, ', speaker: ', not self.settings.flags.mute, ', moderator: ', self.settings.flags.moderator);
  elseif not self.open_for_public then
    self.log:notice('CONFERENCE ', self.id, ' - not open for public');
    return { continue = false, code = 493, phrase = 'Conference closed' };
  end

  caller:answer();
  if not common.str.blank(self.pin) and not self:check_pin(self.pin) then
    self.log:notice('CONFERENCE ', self.id, ' - PIN wrong');
    caller.session:sayPhrase('conference_goodbye');
    return { continue = false, code = 493, phrase = 'Not authorized' };
  end

  self.caller:send_display(tostring(self.record.name) .. ', members: ' .. tostring(members));
  caller:sleep(1000);
  caller.session:sayPhrase('conference_welcome');


  local name_file = nil;
  local name_file_delete = nil;

  if self.announce_entering or self.announce_leaving then
    name_file = self:account_name_file();
    if not name_file then
      name_file = self:record_name(caller);
      name_file_delete = true;
    end
  end

  members = self:members_count();
  if self.announce_entering and name_file then
    if members > 0 then
      self:playback(name_file, self.sounds.has_joined);
    end
  end

  if members == 0 then 
    caller.session:sayPhrase('conference_alone');
  end

  self.caller:send_display(tostring(self.record.name));
  local result =  caller:execute('conference', self.identifier .. "@profile_" .. self.identifier .. "++flags{" .. common.array.keys_to_s(self.settings.flags, '|') .. "}");
  
  self.caller:send_display('Goodbye');
  caller.session:sayPhrase('conference_goodbye');

  if name_file then
    if self.announce_leaving then
      members = self:members_count();
      if members > 0 then
        self:playback(name_file, self.sounds.has_left);
        if members == 1 then 
          self:playback(self.sounds.alone);
        end
      end
    end
    if name_file_delete then
      os.remove(name_file);
    end
  end

  return { continue = false, code = 200, phrase = 'OK' }
end
