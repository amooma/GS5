-- Gemeinschaft 5 module: call router class
-- (c) AMOOMA GmbH 2013
-- 

module(...,package.seeall)

Router = {}

-- create route object
function Router.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.class = 'router';
  self.log = arg.log;
  self.database = arg.database;
  self.routes = arg.routes or {};
  self.caller = arg.caller;
  self.variables = arg.variables or {};
  return object;
end

function Router.build_tables(self)
  local elements = {
    { var_in = 'group', var_out = '', pattern = '^users$', replacement = '', action = 'not_match', mandatory = true },
    { var_in = 'destination_number', var_out = 'destination_number', pattern = '^1$', replacement = '+123456', action = 'not_match', mandatory = true },
    { var_in = 'caller_id_number', var_out = 'caller_id_number', pattern = '^100$', replacement = '+4930100', action = 'set_route_var', mandatory = false },
  }

  local elements2 = {
    { var_in = 'group', var_out = '', pattern = '^users$', replacement = '', action = 'match', mandatory = true },
    { var_in = 'destination_number', var_out = 'destination_number', pattern = '^1$', replacement = '+123456', action = 'not_match', mandatory = true },
    { var_in = 'caller_id_number', var_out = 'caller_id_number', pattern = '^100$', replacement = '+4930100', action = 'set_route_var', mandatory = false },
  }

  local elements3 = {
    { var_in = 'destination_number', var_out = 'destination_number', pattern = '^#31#(%d+)$', replacement = 'f-dcliron-%1', action = 'set_route_var', mandatory = false },
  }

  local elements4 = {
    { var_in = 'destination_number', var_out = 'destination_number', pattern = '^(%d+)$', replacement = '%1', action = 'set_route_var', mandatory = true },
    { var_in = 'caller_id_number', var_out = 'caller_id_number', pattern = '^(.+)$', replacement = '+49%1', action = 'set_route_var', mandatory = false },
  }

  local routes = {
    prerouting = {
      { id = 10, name = 'feature codes', elements = elements3, endpoint_type = 'dialplanfunction', endpoint_id = 0 },
    },
    outbound = {
      { id = 1, name = 'no users', elements = elements, endpoint_type = 'gateway', endpoint_id = 1, },
      { id = 2, name = 'all users', elements = elements2, endpoint_type = 'gateway', endpoint_id = 1, },
      { id = 3, name = 'all users', elements = elements2, endpoint_type = 'gateway', endpoint_id = 1, },
    },
    inbound = {
      { id = 20, name = 'haeron', elements = elements4, endpoint_type = 'phonenumber', endpoint_id = 1, },
    },

  };

  return routes;
end


function Router.failover_table(self)
  return {
    ['603']                  = true,
    ['480']                  = true,
    UNALLOCATED_NUMBER       = true,
    NORMAL_TEMPORARY_FAILURE = true,
  }
end


function Router.expand_variables(self, line)
  return (line:gsub('{([%a%d_]+)}', function(captured)
    return variables[captured] or '';
  end))
end


function Router.set_parameter(self, action, name, value)
  if action == 'set_session_var' then
    self.log:debug('ROUTER_SET_SESSION_VARIABLE - ',  name, ' = ', value);
    self.caller[name] = value;
  elseif action == 'set_channel_var' then
    self.log:debug('ROUTER_SET_VARIABLE - ',  name, ' = ', value);
    self.caller:set_variable(name, value);
  elseif action == 'export_channel_var' then
    self.log:debug('ROUTER_EXPORT_VARIABLE - ',  name, ' = ', value);
    self.caller:export_variable(name, value);
  elseif action == 'set_header' then
    self.log:debug('ROUTER_SIP_HEADER - ',  name, ': ', value);
    self.caller:export_variable('sip_h_' .. name, value);
  else
    self.log:error('ROUTER_SET_PARAMERER - unknown action: ', action, ', ', name, ' = ', value);
  end
end


function Router.element_match(self, pattern, search_string, replacement)
  local variables_list = {};
  local success, result = pcall(string.find, search_string, pattern);

  if not success then
    self.log:error('ELEMENT_MATCH - table error - pattern: ', pattern, ', search_string: ', search_string);
  elseif result then
    return true, search_string:gsub(pattern, self:expand_variables(replacement, variables_list));
  end

  return false;
end


function Router.route_match(self, route)
  local destination = {
    gateway = 'gateway' .. route.endpoint_id,
    ['type'] = route.endpoint_type,
    id = route.endpoint_id,
    actions = {}
  };

  local route_matches = false;

  for index=1, #route.elements do
    local result = false;
    local replacement = nil;

    local element = route.elements[index];
    if element.var_in == 'group' then
      local groups = common.str.try(self.caller, 'auth_account.owner.groups');
      if not groups or type(groups) ~= 'table' then
        if element.mandatory then
          return false;
        end
      end

      for group_name, value in pairs(groups) do
        result, replacement = self:element_match(tostring(element.pattern), tostring(group_name), tostring(element.replacement));
        if result then
          break;
        end
      end
      
    else
      local search_string = tostring(common.str.try(self.caller, element.var_in))
      result, replacement = self:element_match(tostring(element.pattern), tostring(search_string), tostring(element.replacement));
    end

    if element.action == 'not_match' then
      result = not result;
    end

    if not result then
      if element.mandatory then
        return false;
      end
    elseif element.action ~= 'match' and element.action ~= 'not_match' then
      if element.action == 'set_route_var' then
        destination[element.var_out] = replacement;
      else
        table.insert(destination.actions, {action = element.action, name = element.var_out, value = replacement});
      end
    end

    if result then
      route_matches = true;
    end
  end

  if route_matches then
    return destination;
  end;

  return nil;
end


function Router.route_run(self, table_name, phone_number, find_first)
  local routing_tables = self:build_tables();
  local routing_table = routing_tables[table_name];

  local routes = {};

  if type(routing_table) == 'table' then
    for index=1, #routing_table do    
      local route = self:route_match(routing_table[index], phone_number);
      if route then
        table.insert(routes, route);
        self.log:info('ROUTE ', #routes,' - ', table_name,'=', routing_table[index].id, '/', routing_table[index].name, ', destination: ', route.type, '=', route.id);
        if find_first then
          return route;
        end
      else
        self.log:debug('ROUTE_NO_MATCH - ', table_name, '=', routing_table[index].id, '/', routing_table[index].name); 
      end
    end
  end

  if not find_first then
    return routes;
  end
end
