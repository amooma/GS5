-- Gemeinschaft 5 module: intruder class
-- (c) AMOOMA GmbH 2013
--

module(...,package.seeall)


Intruder = {}


function Intruder.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.class = 'intruder'
  self.database = arg.database;

  return object;
end


function Intruder.update_blacklist(self, event)
  local intruder_record = {
    list_type = 'blacklist',
    key = event.key,
    points = event.points,
    bans = event.record.banned,
    contact_ip = event.received_ip,
    contact_port = event.received_port,
    contact_count = event.record.contact_count + 1,
    contact_last = { 'FROM_UNIXTIME(' .. tostring(math.floor(event.timestamp/1000000)) .. ')', raw = true },
    contacts_per_second = event.contacts_per_second,
    contacts_per_second_max = event.contacts_per_second_max,
    user_agent = event.user_agent,
    to_user = event.to_user,
    comment = 'Permimeter',
    created_at = {'NOW()', raw = true },
    updated_at = {'NOW()', raw = true },
  };

  if tonumber(event.ban_time) then
    intruder_record.ban_last = { 'FROM_UNIXTIME(' .. event.ban_time .. ')', raw = true };
  end
  if tonumber(event.ban_end) then
    intruder_record.ban_end = { 'FROM_UNIXTIME(' .. event.ban_end .. ')', raw = true };
  end

  self.database:insert_or_update('intruders', intruder_record, { created_at = false, comment = false });
end


function Intruder.sources_list(self, key)
  local sql_query = nil;

  if key then
    sql_query = 'SELECT * FROM `intruders` WHERE `key` = ' .. self.database:escape(key, '"') .. ' LIMIT 1';
  else
    sql_query = 'SELECT * FROM `intruders`';
  end

  local sources = {};
  local sources_count = 0;
  local blacklist_count = 0;
  local whitelist_count = 0;

  self.database:query(sql_query, function(record)
    sources[record.key] = {
      ignore = (record.list_type == 'whitelist'),
      contact_first = 0,
      contact_last = 0,
      contact_count = record.contact_count,
      span_contact_count = 0,
      span_start = 0,
      points = record.points,
      banned = record.bans,
    };
    sources_count = sources_count + 1;
    if record.list_type == 'whitelist' then
      whitelist_count = whitelist_count + 1;
    elseif record.list_type == 'blacklist' then
      blacklist_count = blacklist_count + 1;
    end
  end);

  self.log:info('[intruder] INTRUDER_LIST - entries loaded: ', sources_count, ', blacklist: ', blacklist_count, ', whitelist: ', whitelist_count);
  
  if key then
    return sources[key];
  end

  return sources;
end
