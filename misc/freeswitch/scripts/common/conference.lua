-- Gemeinschaft 5 module: conference class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

Conference = {}

MEMBERS_MAX = 100;
PIN_LENGTH_MAX = 10;
PIN_LENGTH_MIN = 2;
PIN_TIMEOUT = 4000;
ANNOUNCEMENT_MAX_LEN = 10
ANNOUNCEMENT_SILENCE_THRESHOLD = 500
ANNOUNCEMENT_SILENCE_LEN = 3

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
  self.max_members = 0;
  return object;
end

-- find conference by id
function Conference.find_by_id(self, id)
  local sql_query = 'SELECT * FROM `conferences` WHERE `id`= ' .. tonumber(id) .. '  LIMIT 1';
  local conference = nil;

  self.database:query(sql_query, function(conference_entry)
    conference = Conference:new(self);
    conference.record = conference_entry;
    conference.id = tonumber(conference_entry.id);
    conference.uuid = conference_entry.uuid;
    conference.max_members = tonumber(conference.record.max_members) or MEMBERS_MAX;
  end)

  return conference; 
end

-- find invitee by phone numbers
function Conference.find_invitee_by_numbers(self, phone_numbers)
  if not self.record then 
    return false
  end

  local sql_query = string.format(
  "SELECT `conference_invitees`.`pin` AS `pin`, `conference_invitees`.`speaker` AS `speaker`, `conference_invitees`.`moderator` AS `moderator` " ..
  "FROM `conference_invitees` JOIN `phone_numbers` ON `phone_numbers`.`phone_numberable_id` = `conference_invitees`.`id` " ..
  "WHERE `phone_numbers`.`phone_numberable_type` = 'ConferenceInvitee' AND `conference_invitees`.`conference_id` = %d " ..
  "AND `phone_numbers`.`number` IN ('%s') LIMIT 1", self.record.id, table.concat(phone_numbers, "','"));
  
  local invitee = nil;

  self.database:query(sql_query, function(conference_entry)
    invitee = conference_entry;
  end)

  return invitee; 
end

function Conference.count(self)
  return tonumber(self.caller:result('conference ' .. self.record.id .. ' list count')) or 0;
end

-- Try to enter a conference
function Conference.enter(self, caller, domain)
  local cause = "NORMAL_CLEARING";
  local pin = nil;
  local flags = {'waste'};

  self.caller = caller;

  require "common.phone_number"
  local phone_number_class = common.phone_number.PhoneNumber:new{log = self.log, database = self.database}
  local phone_numbers = phone_number_class:list_by_owner(self.record.id, "Conference");

  -- Set conference presence
  require "dialplan.presence"
  local presence = dialplan.presence.Presence:new();
  presence:init{ log = log, accounts = phone_numbers, domain = domain, uuid = "conference_" .. self.record.id };

  local conference_count = self:count();

  -- Check if conference is full
  if conference_count >= self.max_members then
    presence:early();
    self.log:debug(string.format("full conference %s (\"%s\"), members: %d, members allowed: %d", self.record.id, self.record.name, conference_count, self.max_members));

    if (tonumber(self.record.conferenceable_id) == caller.account_owner_id)
    and (self.record.conferenceable_type == caller.account_owner_type) then
      self.log:debug("Allow owner of this conterence to enter a full conference");
    else
      cause = "CALL_REJECTED";
      caller:hangup(cause);
      return cause;
    end;
  end

  require 'common.str'
  -- Check if conference is within time frame
  if not common.str.blank(self.record.start) and not common.str.blank(self.record['end']) then
    local d = {}
    _,_,d.year,d.month,d.day,d.hour,d.min,d.sec=string.find(self.record.start, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)");

    local conference_start = os.time(d);
    _,_,d.year,d.month,d.day,d.hour,d.min,d.sec=string.find(self.record['end'], "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)");
    local conference_end = os.time(d);
    local now = os.time(os.date("!*t", os.time()));
    
    log:debug("conference - open: " .. os.date("%c",conference_start) .. " by " .. os.date("%c",conference_end) .. ", now: " .. os.date("%c",now));

    if now < conference_start or  now > conference_end then
      cause = "CALL_REJECTED";
      caller:hangup(cause);
      return cause;
    end
  end

  -- Owner ist always moderator
  if (tonumber(self.record.conferenceable_id) == caller.account_owner_id) and (self.record.conferenceable_type == caller.account_owner_type) then
    table.insert(flags, 'moderator');
    log:debug("is owner - conference: " .. self.record.id .. ", owner: " .. caller.account_owner_type .. ":" .. caller.account_owner_id);
  else
    local invitee = self:find_invitee_by_numbers(caller.caller_phone_numbers);

    if not common.str.to_b(self.record.open_for_anybody) and not invitee then
      log:debug(string.format("conference %s (\"%s\"), caller %s not allowed to enter this conference", self.record.id, self.record.name, caller.caller_phone_number));
      cause = "CALL_REJECTED";
      caller:hangup(cause);
      return cause;
    end

    if invitee then
      log:debug("conference " .. self.record.id .. " member invited - speaker: " .. invitee.speaker .. ", moderator: " .. invitee.moderator);
      if common.str.to_b(invitee.moderator) then
        table.insert(flags, 'moderator');
      end
      if not common.str.to_b(invitee.speaker) then
        table.insert(flags, 'mute');
      end
      pin = invitee.pin;
    else
      log:debug("conference " .. self.record.id .. " caller not invited");
    end
  end

  if not pin and self.record.pin then
    pin = self.record.pin
  end

  caller:answer();
  caller:sleep(1000);
  caller.session:sayPhrase('conference_welcome');

  if pin and pin ~= "" then
    local digits = "";
    for i = 1, 3, 1 do
      if digits == pin then
        break
      elseif digits ~= "" then
        caller.session:sayPhrase('conference_bad_pin');
      end
      digits = caller.session:read(PIN_LENGTH_MIN, PIN_LENGTH_MAX, 'conference/conf-enter_conf_pin.wav', PIN_TIMEOUT, '#');
    end
    if digits ~= pin then
      caller.session:sayPhrase('conference_goodbye');
      return "CALL_REJECTED";
    end
  end

  self.log:debug(string.format("entering conference %s - name: \"%s\", flags: %s, members: %d, max. members: %d", 
        self.record.id, self.record.name, table.concat(flags, ','), conference_count, self.max_members));
  
  -- Members count will be incremented in a few milliseconds, set presence
  if (conference_count + 1) >= self.max_members then
    presence:early();
  else
    presence:confirmed();
  end

  -- Enter the conference
  local name_file = nil;

  -- Record caller's name
  if common.str.to_b(self.record.announce_new_member_by_name) or common.str.to_b(self.record.announce_left_member_by_name) then
    local uid = session:get_uuid();
    name_file = "/var/spool/freeswitch/conference_caller_name_" .. uid .. ".wav";
    caller.session:sayPhrase('conference_record_name');
    session:recordFile(name_file, ANNOUNCEMENT_MAX_LEN, ANNOUNCEMENT_SILENCE_THRESHOLD, ANNOUNCEMENT_SILENCE_LEN);
    caller.session:streamFile(name_file);
  end

  -- Play entering caller's name if recorded
  if name_file and (self:count() > 0) and common.str.to_b(self.record.announce_new_member_by_name) then
    caller.session:execute('set',"result=${conference(" .. self.record.id .. " play ".. name_file .. ")}");
    caller.session:execute('set',"result=${conference(" .. self.record.id .. " play conference/conf-has_joined.wav)}");
  else
    -- Ensure a surplus "#" digit is not passed to the conference
    caller.session:read(1, 1, '', 1000, "#");
  end

  local result =  caller.session:execute('conference', self.record.id .. "@profile_" .. self.record.id .. "++flags{" .. table.concat(flags, '|') .. "}");
  self.log:debug('exited conference - result: ' .. tostring(result));
  caller.session:sayPhrase('conference_goodbye');

  -- Play leaving caller's name if recorded
  if name_file then
    if (self:count() > 0) and common.str.to_b(self.record.announce_left_member_by_name) then
      if (self:count() == 1) then 
        caller.session:sleep(3000);
      end
      caller.session:execute('set',"result=${conference(" .. self.record.id .. " play ".. name_file .. ")}");
      caller.session:execute('set',"result=${conference(" .. self.record.id .. " play conference/conf-has_left.wav)}");
    end
    os.remove(name_file);
  end

  -- Set presence according to member count
  conference_count = self:count();
  if conference_count >= self.max_members then
    presence:early();
  elseif conference_count > 0 then
    presence:confirmed();
  else
    presence:terminated();
  end

  cause = "NORMAL_CLEARING";
  caller.session:hangup(cause);
  return cause;
end
