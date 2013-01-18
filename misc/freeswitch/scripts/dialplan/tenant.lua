-- Gemeinschaft 5 module: user class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

Tenant = {}

-- Create Tenant object
function Tenant.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self)
  self.__index = self;
  self.class = 'tenant';
  self.log = arg.log;
  self.database = arg.database;
  self.record = arg.record;
  return object;
end

-- find tenant by id
function Tenant.find_by_id(self, id)
  local sql_query = 'SELECT * FROM `tenants` WHERE `id`= ' .. tonumber(id) .. ' LIMIT 1';
  local tenant = nil;

  self.database:query(sql_query, function(account_entry)
    tenant = Tenant:new(self);
    tenant.record = account_entry;
    tenant.id = tonumber(account_entry.id);
    tenant.uuid = account_entry.uuid;
  end);

  return tenant;
end

-- find tenant by uuid
function Tenant.find_by_uuid(self, uuid)
  tenant_id = tonumber(tenant_id)
  local sql_query = 'SELECT * FROM `tenants` WHERE `id`= "' .. uuid .. '" LIMIT 1';
  local tenant = nil;

  self.database:query(sql_query, function(account_entry)
    tenant = Tenant:new(self);
    tenant.record = account_entry;
    tenant.id = tonumber(account_entry.id);
    tenant.uuid = account_entry.uuid;
  end);

  return tenant;
end
