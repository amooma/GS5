-- Gemeinschaft 5 module: routing class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

Route = {}

-- create route object
function Route.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.database = arg.database;
  self.routing_table = arg.routing_table;
  self.expandable = arg.expandable or {};
  return object;
end

-- find matching routes
function Route.prerouting(self, caller, number)
  require 'common.routing_tables'

  for index, routing_entry in pairs(self.routing_table.prerouting) do
    local route = common.routing_tables.match_route(routing_entry, number);
    if route.error then
      self.log:error('PREROUTE - error: ', route.error);
    elseif route.value then
      self.log:info('ROUTE_PREROUTING - called number: ', number, ', value: ', route.value, ', pattern: ', route.pattern);
      return route;
    end
  end
end

-- find matching routes
function Route.outbound(self, caller, number)
  local routes = {};
  require 'common.routing_tables'
  require 'common.str'

  local ignore_arguments = {
    class=true, 
    endpoint=true,
    pattern=true,
    value=true,
    group=true,
    phrase=true,
  }

  local clip_no_screening = common.str.try(caller, 'account.record.clip_no_screening');
  local caller_id_numbers = {}
  if not common.str.blank(clip_no_screening) then
    for index, number in ipairs(common.str.strip_to_a(clip_no_screening, ',')) do
      table.insert(caller_id_numbers, number);
    end
  end
  for index, number in ipairs(caller.caller_phone_numbers) do
    table.insert(caller_id_numbers, number);
  end
  self.log:info('CALLER_ID_NUMBER - caller_id_numbers: ', table.concat(caller_id_numbers, ','));

  for index, routing_entry in pairs(self.routing_table.outbound) do
    local route = common.routing_tables.match_route(routing_entry, number);
    if route.error then
      self.log:error('ROUTE_OUTBOUND - error: ', route.error);
    elseif route.value then
      local valid_route = true;

      for argument, value in pairs(route) do
        if not ignore_arguments[argument] then
          local table_value = common.str.downcase(tostring(common.str.try(caller, argument)));
          value = common.str.downcase(tostring(value));
          if table_value:match(value) then
            self.log:info('ROUTE_OUTBOUND_POSITIVE - ', argument, '=', value, ' ~ ', table_value, ', pattern: ', route.pattern);
          else
            self.log:info('ROUTE_OUTBOUND_NEGATIVE - ', argument, '=', value, ' !~ ', table_value, ', pattern: ', route.pattern);
            valid_route = false;
          end
        end
      end  

      if route.group then
        if common.str.try(caller.auth_account, 'owner.groups.' .. tostring(route.group)) then
          self.log:info('ROUTE_OUTBOUND_POSITIVE - group=', route.group, ', pattern: ', route.pattern);
        else
          self.log:info('ROUTE_OUTBOUND_NEGATIVE - group=', route.group, ', pattern: ', route.pattern);
          valid_route = false;
        end
      end

      if route.cidn then
        if caller.caller_id_number:match(route.cidn) then
          self.log:info('ROUTE_OUTBOUND_POSITIVE - cidn=', route.cidn, ' ~ ', caller.caller_id_number,', pattern: ', route.pattern);
        else
          self.log:info('ROUTE_OUTBOUND_NEGATIVE - cidn=', route.cidn, ' !~ ', caller.caller_id_number, ', pattern: ', route.pattern);
          valid_route = false;
        end
      end

      if valid_route then
        if route.class ~= 'hangup' then
          route.caller_id_number = self:outbound_cid_number(caller, caller_id_numbers, route.endpoint, route.class);
          self.expandable.caller_id_number = route.caller_id_number;
          route.caller_id_name   = self:outbound_cid_name(caller, route.endpoint, route.class);
        end
        table.insert(routes, route);
        self.log:info('ROUTE_OUTBOUND ', #routes,' - ', route.class, '=', route.endpoint, ', value: ', route.value, ', caller_id_number: ', route.caller_id_number, ', caller_id_name: ', route.caller_id_name);
      end
    end
  end

  return routes;
end


function Route.inbound(self, caller, number)
  require 'common.routing_tables'

  local ignore_arguments = {
    class=true, 
    endpoint=true,
    pattern=true,
    value=true,
    group=true,
    phrase=true,
  }

  for index, routing_entry in pairs(self.routing_table.inbound) do
    local route = common.routing_tables.match_route(routing_entry, number);
    if route.error then
      self.log:error('ROUTE_INBOUND - error: ', route.error);
    elseif route.value then
      local valid_route = true;

      for argument, value in pairs(route) do
        if not ignore_arguments[argument] then
          local table_value = common.str.downcase(tostring(common.str.try(caller, argument)));
          value = common.str.downcase(tostring(value));
          if table_value:match(value) then
            self.log:info('ROUTE_INBOUND_POSITIVE - ', argument, '=', value, ' ~ ', table_value, ', pattern: ', route.pattern);
          else
            self.log:info('ROUTE_INBOUND_NEGATIVE - ', argument, '=', value, ' !~ ', table_value, ', pattern: ', route.pattern);
            valid_route = false;
          end
        end
      end

      if route.class and route.endpoint then
        if route.class == 'gateway' and caller.gateway_name:match(route.endpoint) then
          self.log:info('ROUTE_INBOUND_POSITIVE - ', route.class, '=', route.endpoint, ' ~ ', caller.gateway_name, ', pattern: ', route.pattern);
        else
          self.log:info('ROUTE_INBOUND_NEGATIVE - ', route.class, '=', route.endpoint, ' !~ ', caller.gateway_name, ', pattern: ', route.pattern);
          valid_route = false;
        end
      end

      if valid_route then
        self.log:info('ROUTE_INBOUND - called number: ', number, ', value: ', route.value, ', pattern: ', route.pattern);
        return route;
      end
    end
  end
end

-- find caller id
function Route.caller_id(self, caller, cid_entry, search_str, endpoint, class)
  local ignore_arguments = {
    class=true, 
    endpoint=true,
    pattern=true,
    value=true,
    group=true,
    phrase=true,
  }

  local route = common.routing_tables.match_route(cid_entry, search_str, self.expandable);
  if route.error then
    self.log:error('CALLER_ID - error: ', route.error);
  elseif route.value then
    local valid_route = true;

    for argument, value in pairs(route) do
      if not ignore_arguments[argument] then
        local table_value = common.str.downcase(tostring(common.str.try(caller, argument)));
        value = common.str.downcase(tostring(value));
        if table_value:match(value) then
          self.log:debug('CALLER_ID_POSITIVE - ', argument, '=', value, ' ~ ', table_value, ', pattern: ', route.pattern);
        else
          self.log:debug('CALLER_ID_NEGATIVE - ', argument, '=', value, ' !~ ', table_value, ', pattern: ', route.pattern);
          valid_route = false;
        end
      end
    end  

    if route.group then
      if common.str.try(caller.auth_account, 'owner.groups.' .. tostring(route.group)) then
        self.log:debug('CALLER_ID_POSITIVE - group=', route.group, ', pattern: ', route.pattern);
      else
        self.log:debug('CALLER_ID_NEGATIVE - group=', route.group, ', pattern: ', route.pattern);
        valid_route = false;
      end
    end

    endpoint = tostring(endpoint);
    if route.class and route.endpoint then
      if route.class == 'gateway' and endpoint:match(route.endpoint) then
        self.log:debug('CALLER_ID_POSITIVE - ', route.class, '=', route.endpoint, ' ~ ', endpoint, ', pattern: ', route.pattern);
      else
        self.log:debug('CALLER_ID_NEGATIVE - ', route.class, '=', route.endpoint, ' !~ ', endpoint, ', pattern: ', route.pattern);
        valid_route = false;
      end
    end

    if valid_route then
      self.log:debug('CALLER_ID ', route.class, '=', route.endpoint, ', value: ', route.value);
      return route.value;
    end
  end

  return nil;
end

-- find matching caller id number
function Route.outbound_cid_number(self, caller, caller_id_numbers, endpoint, class)
  for route_index, cid_entry in pairs(self.routing_table.outbound_cid_number) do
    for index, number in ipairs(caller_id_numbers) do
      local route = self:caller_id(caller, cid_entry, number, endpoint, class);
      if route then
        return route;
      end
    end
  end
end

-- find matching caller id name
function Route.outbound_cid_name(self, caller, endpoint, class)
  for route_index, cid_entry in pairs(self.routing_table.outbound_cid_name) do 
    local route = self:caller_id(caller, cid_entry, caller.caller_id_name, endpoint, class);
    if route then
      return route;
    end
  end
end

-- find matching caller id number
function Route.inbound_cid_number(self, caller, endpoint, class)
  for route_index, cid_entry in pairs(self.routing_table.inbound_cid_number) do 
    local route = self:caller_id(caller, cid_entry, caller.caller_id_number, endpoint, class);
    if route then
      return route;
    end
  end
end

-- find matching caller id name
function Route.inbound_cid_name(self, caller, endpoint, class)
  for route_index, cid_entry in pairs(self.routing_table.inbound_cid_name) do 
    local route = self:caller_id(caller, cid_entry, caller.caller_id_name, endpoint, class);
    if route then
      return route;
    end
  end
end
