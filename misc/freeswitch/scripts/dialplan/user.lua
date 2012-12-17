-- Gemeinschaft 5 module: user class
-- (c) AMOOMA GmbH 2012
-- 

module(...,package.seeall)

User = {}

MAX_GROUP_MEMBERSHIPS = 256;

-- create user object
function User.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.class = 'user';
  self.log = arg.log;
  self.database = arg.database;
  self.record = arg.record;
  return object;
end

-- find user by id
function User.find_by_id(self, id)
  local sql_query = 'SELECT * FROM `users` WHERE `id`= ' .. tonumber(id) .. ' LIMIT 1';
  local user = nil;

  self.database:query(sql_query, function(account_entry)
    user = User:new(self);
    user.record = account_entry;
    user.id = tonumber(account_entry.id);
    user.uuid = account_entry.uuid;
  end);

  return user;
end

-- find user by uuid
function User.find_by_uuid(self, uuid)
  local sql_query = 'SELECT * FROM `users` WHERE `id`= "' .. uuid .. '" LIMIT 1';
  local user = nil;

  self.database:query(sql_query, function(account_entry)
    user = User:new(self);
    user.record = account_entry;
    user.id = tonumber(account_entry.id);
    user.uuid = account_entry.uuid;
  end);

  return user;
end


function User.list_groups(self, id)
  require 'common.str'
  id = id or self.id;
  local sql_query = 'SELECT `b`.`name` FROM `user_group_memberships` `a` \
    JOIN `user_groups` `b` ON `a`.`user_group_id` = `b`.`id` \
    WHERE `a`.`state` = "active" AND `a`.`user_id`= ' .. tonumber(id) .. ' ORDER BY `b`.`position` LIMIT ' .. MAX_GROUP_MEMBERSHIPS;
  
  local groups = {};

  self.database:query(sql_query, function(entry)
    groups[common.str.downcase(entry.name)] = true;
  end);

  return groups;
end


function User.check_pin(self, pin_to_check)
  if not self.record then
    return nil
  end

  local str_to_hash = tostring(self.record.pin_salt) .. tostring(pin_to_check);

  local file = io.popen("echo -n " .. str_to_hash .. "|sha256sum");
  local pin_to_check_hash = file:read("*a");
  file:close();

  pin_to_check_hash = pin_to_check_hash:sub(1, 64);

  if pin_to_check_hash == self.record.pin_hash then
    return true;
  end

  return false;
end

