-- CommonModule: AccessAuthorization
--
module(...,package.seeall)

AccessAuthorization = {}

-- Create AccessAuthorization object
function AccessAuthorization.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self)
  self.__index = self
  self.log = arg.log
  self.database = arg.database
  self.record = arg.record
  self.session = arg.session
  return object
end

-- Find AccessAuthorization by ID
function AccessAuthorization.find_by_id(self, id)
  local sql_query = string.format("SELECT * FROM `access_authorizations` WHERE `id`=%d LIMIT 1", id)
  local record = nil

  self.database:query(sql_query, function(access_authorization_entry)
    record = access_authorization_entry
  end)

  if record then
    access_authorization = AccessAuthorization:new(self)
    access_authorization.record = record
    return access_authorization
  end

  return nil 
end

-- list accessauthorization by owner
function AccessAuthorization.list_by_owner(self, owner_id, owner_type)
  local sql_query = 'SELECT `a`.`id`, `a`.`name`, `a`.`login`, `a`.`pin`, `a`.`sip_account_id`, `b`.`number` AS `phone_number` \
    FROM `access_authorizations` `a` \
    LEFT JOIN `phone_numbers` `b` ON `b`.`phone_numberable_id` = `a`.`id` AND `b`.`phone_numberable_type` = "AccessAuthorization" \
    WHERE `a`.`access_authorizationable_type` = "' .. owner_type .. '" AND `access_authorizationable_id`= ' .. tonumber(owner_id);

  local access_authorizations = {}

  self.database:query(sql_query, function(access_authorization_entry)
    table.insert(access_authorizations, access_authorization_entry);
  end);

  return access_authorizations;
end
