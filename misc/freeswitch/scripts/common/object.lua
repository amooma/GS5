-- Gemeinschaft 5 module: object class
-- (c) AMOOMA GmbH 2013
-- 

module(...,package.seeall)

Object = {}

-- create object object ;)
function Object.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.class = 'object';
  self.log = arg.log;
  self.database = arg.database;
  return object;
end

-- find object
function Object.find(self, attributes)
  if not attributes.class then
    return nil;
  end

  local object = nil;

  require 'common.str';
  local class = common.str.downcase(attributes.class);

  if class == 'user' then
    require 'dialplan.user';
    if tonumber(attributes.id) then
      object = dialplan.user.User:new{ log = self.log, database = self.database }:find_by_id(attributes.id);
    elseif not common.str.blank(attributes.uuid) then
      object = dialplan.user.User:new{ log = self.log, database = self.database }:find_by_uuid(attributes.uuid);
    end

    if object then
      object.user_groups = object:list_groups();
    end
  elseif class == 'tenant' then
    require 'dialplan.tenant';
    if tonumber(attributes.id) then
      object = dialplan.tenant.Tenant:new{ log = self.log, database = self.database }:find_by_id(attributes.id);
    elseif not common.str.blank(attributes.uuid) then
      object = dialplan.tenant.Tenant:new{ log = self.log, database = self.database }:find_by_uuid(attributes.uuid);
    end
  elseif class == 'sipaccount' then
    require 'common.sip_account';
    if not common.str.blank(attributes.auth_name) then
      object = common.sip_account.SipAccount:new{ log = self.log, database = self.database }:find_by_auth_name(attributes.auth_name, attributes.domain);
    elseif tonumber(attributes.id) then
      object = common.sip_account.SipAccount:new{ log = self.log, database = self.database }:find_by_id(attributes.id);
    elseif not common.str.blank(attributes.uuid) then
      object = common.sip_account.SipAccount:new{ log = self.log, database = self.database }:find_by_uuid(attributes.uuid);
    end

    if object then
      object.owner = self:find{class = object.record.sip_accountable_type, id = tonumber(object.record.sip_accountable_id)};
    end
  elseif class == 'huntgroup' then
    require 'dialplan.hunt_group';

    if tonumber(attributes.id) then
      object = dialplan.hunt_group.HuntGroup:new{ log = self.log, database = self.database }:find_by_id(attributes.id);
    elseif not common.str.blank(attributes.uuid) then
      object = dialplan.hunt_group.HuntGroup:new{ log = self.log, database = self.database }:find_by_uuid(attributes.uuid);
    end

    if object then
      object.owner = self:find{class = 'tenant', id = tonumber(object.record.tenant_id)};
    end
  elseif class == 'automaticcalldistributor' then
    require 'dialplan.acd';

    if tonumber(attributes.id) then
      object = dialplan.acd.AutomaticCallDistributor:new{ log = self.log, database = self.database, domain = self.domain }:find_by_id(attributes.id);
    elseif not common.str.blank(attributes.uuid) then
      object = dialplan.acd.AutomaticCallDistributor:new{ log = self.log, database = self.database, domain = self.domain }:find_by_uuid(attributes.uuid);
    end

    if object then
      object.owner = self:find{class = object.record.automatic_call_distributorable_type, id = tonumber(object.record.automatic_call_distributorable_id)};
    end
  elseif class == 'faxaccount' then
    require 'dialplan.fax';
    if tonumber(attributes.id) then
      object = dialplan.fax.Fax:new{ log = self.log, database = self.database }:find_by_id(attributes.id);
    elseif not common.str.blank(attributes.uuid) then
      object = dialplan.fax.Fax:new{ log = self.log, database = self.database }:find_by_uuid(attributes.uuid);
    end

    if object then
      object.owner = self:find{class = object.record.fax_accountable_type, id = tonumber(object.record.fax_accountable_id)};
    end
  end

  if object then
    require 'common.group';
    object.groups, object.group_ids = common.group.Group:new{ log = self.log, database = self.database }:name_id_by_member(object.id, object.class);
  end

  return object;
end
