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
    AND `c`.`active` IS TRUE \
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
      AND `c`.`active` IS TRUE \
      GROUP BY `b`.`group_id` LIMIT ' .. MAX_GROUP_MEMBERSHIPS;

  local group_names = {};
  local group_ids = {};

  self.database:query(sql_query, function(account_entry)
    table.insert(group_names, account_entry.name);
    table.insert(group_ids, tonumber(account_entry.id));
  end);

  return group_names, group_ids;
end

function Group.permission_targets(self, group_ids, permission)
  if not group_ids or not permission then
    return {};
  end

  local sql_query = 'SELECT DISTINCT `b`.`id`, `b`.`name` \
    FROM `group_permissions` `a` \
    JOIN `groups` `b` ON `b`.`id` = `a`.`target_group_id` \
    WHERE `a`.`permission` = ' .. self.database:escape(permission, '"') .. ' \
    AND `a`.`group_id` IN (' .. table.concat(group_ids, ',') .. ') \
    AND `b`.`active` IS TRUE \
    GROUP BY `a`.`target_group_id` LIMIT ' .. MAX_GROUP_MEMBERSHIPS;


  local groups = {};

  self.database:query(sql_query, function(account_entry)
    groups[account_entry.id] = account_entry.name;
  end);

  return groups;
end


function Group.combine(self, ...)
  local groups = {};
  local group_sets = {...};
  for set_index=1, #group_sets do
    if type(group_sets[set_index]) == 'table' then
      local group_ids = group_sets[set_index];
      for index=1, #group_ids do
        groups[tonumber(group_ids[index])] = true;
      end
    end
  end

  local group_ids = {};
  for group_id, status in pairs(groups) do
    table.insert(group_ids, group_id);
  end

  return group_ids;
end
