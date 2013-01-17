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


function Router.read_table(self, table_name)
  local routing_table = {};

  local sql_query = 'SELECT * \
    FROM `call_routes` `a` \
    JOIN `route_elements` `b` ON `a`.`id` = `b`.`call_route_id`\
    WHERE `a`.`table` = "' .. table_name .. '" \
    ORDER BY `a`.`position`, `b`.`position`';

  local last_id = 0;
  self.database:query(sql_query, function(route)
    if last_id ~= tonumber(route.call_route_id) then
      last_id = tonumber(route.call_route_id);
      table.insert(routing_table, {id = route.call_route_id, name = route.name, endpoint_type = route.endpoint_type , endpoint_id = route.endpoint_id, elements = {} });
    end
    
    table.insert(routing_table[#routing_table].elements, {
      var_in = route.var_in, 
      var_out = route.var_out, 
      pattern = route.pattern,
      replacement = route.replacement, 
      action = route.action,
      mandatory = common.str.to_b(route.mandatory),
    }); 
  end);

  return routing_table;
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


function Router.element_match_group(self, pattern, groups, replacement, use_key)
  if type(groups) ~= 'table' then
    return false;
  end

  for key, value in pairs(groups) do
    if use_key then 
      value = key;
    end
    result, replaced_value = self:element_match(pattern, tostring(value), replacement);
    if result then
      return true, replaced_value;
    end
  end
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
    local command, variable_name = common.str.partition(element.var_in, ':');

    if not command or not variable_name or command == 'var' then
      local search_string = tostring(common.str.try(self.caller, element.var_in))
      result, replacement = self:element_match(tostring(element.pattern), tostring(search_string), tostring(element.replacement));
    elseif command == 'key' or command == 'val' then
      local groups = common.str.try(self.caller, variable_name);
      result, replacement = self:element_match_group(tostring(element.pattern), groups, tostring(element.replacement), command == 'key');
    elseif command == 'chv' then
      local search_string = self.caller:to_s(variable_name);
      result, replacement = self:element_match(tostring(element.pattern), search_string, tostring(element.replacement));
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
  local routing_table = self:read_table(table_name);
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
