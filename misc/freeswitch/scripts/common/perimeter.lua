-- Gemeinschaft 5 module: perimeter class
-- (c) AMOOMA GmbH 2013
--

module(...,package.seeall)


Perimeter = {}


function Perimeter.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.class = 'perimeter'
  self.database = arg.database;
  self.domain = arg.domain;
  self.sources = {};

  self.checks_available = {
    check_frequency = self.check_frequency,
    check_username_scan = self.check_username_scan,
    check_bad_headers = self.check_bad_headers,
  };

  return object;
end


function Perimeter.setup(self, event)
  require 'common.configuration_table';
  local config = common.configuration_table.get(self.database, 'perimeter');

  self.contact_count_threshold = 10;
  self.contact_span_threshold = 2;
  self.name_changes_threshold = 2;
  self.blacklist_file = '/var/opt/gemeinschaft/firewall/blacklist';
  self.blacklist_file_comment = '# PERIMETER_BAN - points: {points}, generated: {date}';
  self.blacklist_file_entry = '{received_ip} udp 5060';
  self.ban_command = 'sudo /sbin/service shorewall refresh';
  self.ban_threshold = 20;
  self.ban_tries = 1;

  if config and config.general then
    for key, value in pairs(config.general) do
      self[key] = value;
    end
  end

  self.checks = config.checks;
  self.bad_headers = config.bad_headers;

  self.log:info('[perimeter] PERIMETER - setup perimeter defense');
end


function Perimeter.record_load(self, event)
  if not self.sources[event.key] then
    self.sources[event.key] = {
      contact_first = event.timestamp,
      contact_last = event.timestamp,
      contact_count = 0,
      span_contact_count = 0,
      span_start = event.timestamp,
      points = 0,
      banned = 0,
    }
  end

  return self.sources[event.key];
end


function Perimeter.format_date(self, value)
  local epoch = tonumber(tostring(value/1000000):match('^(%d-)%.'));
  return os.date('%Y-%m-%d %X', tonumber(epoch)) .. '.' .. (value-(epoch*1000000));
end


function Perimeter.record_update(self, event)
  event.record.contact_last = event.timestamp;
  event.record.contact_count = event.record.contact_count + 1;
  event.record.points = event.points or event.record.points;
  event.record.span_start = event.span_start or event.record.span_start;
  event.record.span_contact_count = (event.span_contact_count or event.record.span_contact_count) + 1;
  event.record.users = event.users or event.record.users;
end


function Perimeter.check(self, event)
  event.record = self:record_load(event);
  -- self.log:debug('[', event.key, '/', event.sequence, '] PERIMETER_CHECK - received: ', event.received_ip, ':', event.received_port, ', contacts: ', event.record.contact_count, ', since: ', self:format_date(event.record.contact_first), ', points: ', event.record.points);
  
  if event.record.banned <= self.ban_tries then
    for check_name, check_points in pairs(self.checks) do
      if self.checks_available[check_name] then
        local result = self.checks_available[check_name](self, event);
        if tonumber(result) then
          event.points = (event.points or event.record.points) + result * check_points;
        end
      end
    end
  end

  if (event.points or event.record.points) > self.ban_threshold and event.record.banned <= self.ban_tries then
    if event.record.banned > 0 and event.record.banned == self.ban_tries then
      self.log:warning('[', event.key, '/', event.sequence, '] PERIMETER_BAN_FUTILE - points: ', event.points,', event: ', event.class, ', from: ', event.from_user, '@', event.from_host, ', to: ', event.to_user, '@', event.to_host);
    else  
      self.log:notice('[', event.key, '/', event.sequence, '] PERIMETER_BAN - threshold reached: ', event.points,', event: ', event.class, ', from: ', event.from_user, '@', event.from_host, ', to: ', event.to_user, '@', event.to_host);
      if event.record.banned == 0 then
        self:append_blacklist_file(event);
      end
      self:execute_ban(event);
    end
        
    event.record.banned = event.record.banned + 1;
    event.span_start = event.timestamp;
    event.span_contact_count = 0;
    event.points = 0;
  end

  self:record_update(event);
end


function Perimeter.check_frequency(self, event)
  if event.record.span_contact_count >= self.contact_count_threshold then
    self.log:info('[', event.key, '/', event.sequence, '] PERIMETER_FREQUENCY_CHECK - contacts: ', event.record.span_contact_count, ' in < ', (event.timestamp - event.record.span_start)/1000000, ' sec, threshold: ', self.contact_count_threshold, ' in ', self.contact_span_threshold, ' sec');
    event.span_contact_count = 0;
    event.span_start = event.timestamp;
    return 1;
  elseif (event.timestamp - event.record.span_start) > (self.contact_span_threshold * 1000000) then    
    event.span_contact_count = 0;
    event.span_start = event.timestamp;
  end
end


function Perimeter.check_username_scan(self, event)
  if not event.to_user then
    return;
  end

  if not event.record.users then
    event.users = { event.to_user };
    return;
  end

  if #event.record.users >= self.name_changes_threshold then
    self.log:info('[', event.key, '/', event.sequence, '] PERIMETER_USER_SCAN - user names: ', #event.record.users, ', threshold: ', self.name_changes_threshold);
    event.users = {};
    return 1;
  else
    for index=1, #event.record.users do
      if event.record.users[index] == tostring(event.to_user) then
        return
      end
    end

    if not event.users then
      event.users = event.record.users or {};
    end
    table.insert(event.users, tostring(event.to_user));
  end
end


function Perimeter.check_bad_headers(self, event)
  local points = nil;
  for name, pattern in pairs(self.bad_headers) do
    local success, result = pcall(string.find, event[name], pattern);
    if success and result then
      self.log:info('[', event.key, '/', event.sequence, '] PERIMETER_BAD_HEADERS - ', name, '=', event[name], ' ~= ', pattern);
      points = (points or 0) + 1;
    end
  end

  return points;
end


function Perimeter.append_blacklist_file(self, event)
  local blacklist = io.open(self.blacklist_file, 'a');
  if not blacklist then
    self.log:error('[', event.key, '/', event.sequence, '] PERIMETER_APPEND_BLACKLIST - could not open file: ', self.blacklist_file);
    return false;
  end

  event.date = self:format_date(event.timestamp);

  if self.blacklist_file_comment then  
    blacklist:write(self:expand_variables(self.blacklist_file_comment, event), '\n');
  end

  self.log:debug('[', event.key, '/', event.sequence, '] PERIMETER_APPEND_BLACKLIST - file: ', self.blacklist_file);
  blacklist:write(self:expand_variables(self.blacklist_file_entry, event), '\n');
  blacklist:close();
end


function Perimeter.execute_ban(self, event)
  local command = self:expand_variables(self.ban_command, event);
  self.log:debug('[', event.key, '/', event.sequence, '] PERIMETER_EXECUTE_BAN - command: ', command);
  local result = os.execute(command);
end


function Perimeter.expand_variables(self, line, variables)
  return (line:gsub('{([%a%d%._]+)}', function(captured)
    return variables[captured] or '';
  end))
end
