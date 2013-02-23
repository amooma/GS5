-- Gemeinschaft 5 module: group class
-- (c) AMOOMA GmbH 2013
-- 

module(...,package.seeall)

Group = {}

MAX_GROUP_MEMBERSHIPS = 256;

-- create group object
function Group.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.class = 'group';
  self.log = arg.log;
  self.database = arg.database;
  return object;
end

-- find group by id
function Group.find_by_id(self, id)
  local sql_query = 'SELECT * FROM `groups` WHERE `id`= ' .. tonumber(id) .. ' LIMIT 1';
  local group = nil;

  self.database:query(sql_query, function(account_entry)
    group = Group:new(self);
    group.record = account_entry;
    group.id = tonumber(account_entry.id);
    group.name = account_entry.name;
  end);

  return group;
end

-- list groups by member permissions
function Group.name_id_by_permission(self, member_id, member_type, permission)
  if not tonumber(member_id) then
    return {};
  end

  local sql_query = 'SELECT DISTINCT `c`.`id`, `c`.`name` \
    FROM `group_permissions` `a` \
    JOIN `group_memberships` `b` ON `a`.`target_group_id` = `b`.`group_id` \
    JOIN `groups` `c` ON `c`.`id` = `b`.`group_id` \
    WHERE `b`.`item_type` = ' .. self.database:escape(member_type, '"') .. ' \
    AND `b`.`item_id` = ' .. member_id .. ' \
    AND `a`.`permission` = ' .. self.database:escape(permission, '"') .. ' \
    GROUP BY `b`.`group_id` LIMIT ' .. MAX_GROUP_MEMBERSHIPS;

  local group_names = {};
  local group_ids = {};

  self.database:query(sql_query, function(account_entry)
    table.insert(group_names, account_entry.name);
    table.insert(group_ids, tonumber(account_entry.id));
  end);

  return group_names, group_ids;
end

-- list groups by member
function Group.name_id_by_member(self, member_id, member_type)
  if not tonumber(member_id) then
    return {};
  end

  local sql_query = 'SELECT DISTINCT `c`.`id`, `c`.`name` \
      FROM `group_memberships` `b` \
      JOIN `groups` `c` ON `c`.`id` = `b`.`group_id` \
      WHERE `b`.`item_type` = ' .. self.database:escape(member_type, '"') .. ' \
      AND `b`.`item_id` = ' .. member_id .. ' \
      GROUP BY `b`.`group_id` LIMIT ' .. MAX_GROUP_MEMBERSHIPS;

  local group_names = {};
  local group_ids = {};

  self.database:query(sql_query, function(account_entry)
    table.insert(group_names, account_entry.name);
    table.insert(group_ids, tonumber(account_entry.id));
  end);

  return group_names, group_ids;
end
