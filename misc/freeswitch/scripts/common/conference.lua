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

  settings.members_max = settings.members_max or tonumber(parameters['max-members']) or 100;
  settings.pin_length_max = tonumber(settings.pin_length_max) or 10;
  settings.pin_length_min = tonumber(settings.pin_length_min) or 2;
  settings.pin_timeout = tonumber(settings.pin_timeout) or 4000;
  settings.announcement_max_length = tonumber(settings.announcement_max_length) or 10;
  settings.announcement_silence_threshold = tonumber(settings.announcement_silence_threshold) or 500;
  settings.announcement_silence_length = tonumber(settings.announcement_silence_length) or 3;
  settings.flags = settings.flags or { waste = true };
  settings.pin_sound = parameters['pin-sound'];
  settings.pin_bad_sound = parameters['bad-pin-sound'];
  settings.key_enter = parameters.key_enter or '#';
  settings.phrase_welcome = settings.phrase_welcome or 'conference_welcome';
  settings.phrase_goodbye = settings.phrase_goodbye or 'conference_goodbye';
  settings.phrase_record_name = settings.phrase_record_name or 'conference_record_name';
  settings.spool_dir = settings.spool_dir or '/var/spool/freeswitch';
  return settings;
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

    conference.settings = self:settings_get();
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
      break
    elseif digits ~= "" then
      if self.settings.pin_bad_sound then
        self.caller:playback(self.settings.pin_bad_sound);
      else
        self.caller.session:sayPhrase('conference_bad_pin');
      end
    end
    digits = self.caller.session:read(self.settings.pin_length_min, self.settings.pin_length_max, self.settings.pin_sound, self.settings.pin_timeout, self.settings.key_enter);
  end

  if digits ~= pin then
    return false
  end

  return true;
end


function Conference.check_ownership(self)
  local auth_account_owner = common.array.try(self.caller, 'auth_account.owner');
  if not auth_account_owner then
    return false;
  end

  if tonumber(self.record.conferenceable_id) == auth_account_owner.id and self.record.conferenceable_type:lower() == auth_account_owner.class then
    return true;
  end
end


function Conference.record_name(self)
  if not self.announce_entering and not announce_leaving then
    return nil;
  end

  local name_file = self.settings.spool_dir .. '/conference_caller_name_' .. self.caller.uuid .. '.wav';
  self.caller.session:sayPhrase(self.settings.phrase_record_name);
  self.caller.session:recordFile(name_file, self.settings.announcement_max_length, self.settings.announcement_silence_threshold, self.settings.announcement_max_length);
  self.caller:playback(name_file);

  return name_file;
end


function Conference.playback(self, file_name)
  self.caller:execute('set',"result=${conference(" .. self.identifier .. " play ".. file_name .. ")}");
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
    self.settings.flags.mute = not common.str.to_b(invitee.speaker);
    self.settings.flags.moderator = common.str.to_b(invitee.moderator);
    self.log:info('CONFERENCE ', self.id, ' - invitee=', invitee.id, '/', invitee.uuid, ', speaker: ', not self.settings.flags.mute, ', moderator: ', self.settings.flags.moderator);
    self.pin = invitee.pin;
  elseif self:check_ownership() then
    self.settings.flags.moderator = true;
    self.pin = nil;
    self.log:info('CONFERENCE ', self.id, ' - owner authenticated: ', self.caller.auth_account.owner.class,'=', self.caller.auth_account.owner.id, '/', self.caller.auth_account.owner.uuid, ', speaker: ', not self.settings.flags.mute, ', moderator: ', self.settings.flags.moderator);
  elseif not self.open_for_public then
    self.log:notice('CONFERENCE ', self.id, ' - not open for public');
    return { continue = false, code = 493, phrase = 'Conference closed' };
  end

  if not common.str.blank(self.pin) and not self:check_pin(self.pin) then
    self.log:notice('CONFERENCE ', self.id, ' - PIN wrong');
    if self.settings.phrase_goodbye then
      caller.session:sayPhrase(self.settings.phrase_goodbye);
    end
    return { continue = false, code = 493, phrase = 'Not authorized' };
  end

  caller:answer();
  caller:sleep(1000);
  if self.settings.phrase_welcome then
    caller.session:sayPhrase('conference_welcome');
  end

  local name_file = self:record_name(caller);
  if name_file then
    if self.announce_entering then
      members = self:members_count();
      if members > 0 then
        caller.session:sayPhrase('conference_has_joined', name_file);
      end
    end
  end

  local result =  caller:execute('conference', self.identifier .. "@profile_" .. self.identifier .. "++flags{" .. common.array.keys_to_s(self.settings.flags, '|') .. "}");
  if self.settings.phrase_goodbye then
    caller.session:sayPhrase(self.settings.phrase_goodbye);
  end

  if name_file then
    if self.announce_leaving then
      members = self:members_count();
      if members > 0 then
        if members == 1 then 
          caller:sleep(3000);
        end
        caller.session:sayPhrase('conference_has_left', name_file);
      end
    end
    os.remove(name_file);
  end

  return { continue = false, code = 200, phrase = 'OK' }
end
