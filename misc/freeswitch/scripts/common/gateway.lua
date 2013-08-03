-- Gemeinschaft 5 module: gateway class
-- (c) AMOOMA GmbH 2013
-- 

module(...,package.seeall)

Gateway = {}

-- Create Gateway object
function Gateway.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.class = 'gateway';
  self.log = arg.log;
  self.database = arg.database;
  self.record = arg.record;
  self.GATEWAY_PREFIX = 'gateway';
  return object;
end


function Gateway.list(self, technology)
  technology = technology or 'sip';
  local sql_query = 'SELECT * FROM `gateways` WHERE (`outbound` IS TRUE OR `inbound` IS TRUE) AND `technology` = "' .. technology .. '"';
  local gateways = {};
  self.database:query(sql_query, function(entry)
    table.insert(gateways, entry);
  end)

  return gateways;
end


function Gateway.find_by_id(self, id)
  if not tonumber(id) then
    return nil;
  end

  local sql_query = 'SELECT `a`.*, `c`.`sip_host` AS `domain`, `c`.`contact` AS `contact_full`, `c`.`network_ip`, `c`.`network_port` \
    FROM `gateways` `a` \
    LEFT JOIN `gateway_settings` `b` ON `a`.`id` = `b`.`gateway_id` AND `b`.`name` = "inbound_username" \
    LEFT JOIN `sip_registrations` `c` ON `b`.`value` = `c`.`sip_user` \
    WHERE `a`.`id`= ' .. tonumber(id) .. ' LIMIT 1';

  local gateway = nil;
  self.database:query(sql_query, function(entry)
    require 'common.str';
    gateway = Gateway:new(self);
    gateway.record = entry;
    gateway.id = tonumber(entry.id);
    gateway.name = entry.name;
    gateway.technology = entry.technology;
    gateway.outbound = common.str.to_b(entry.outbound);
    gateway.inbound = common.str.to_b(entry.inbound);
    gateway.domain = entry.domain;
    gateway.network_ip = entry.network_ip;
    gateway.network_port = tonumber(entry.network_port) or 5060;
  end)

  if gateway then
    gateway.settings = self:config_table_get('gateway_settings', gateway.id);
    if common.str.blank(gateway.domain) then
      gateway.domain = gateway.settings.domain;
    end
  end

  return gateway;
end


function Gateway.find_by_name(self, name)
  local gateway_name = name:gsub('([^%a%d%._%+])', '');

  local sql_query = 'SELECT `a`.*, `c`.`sip_host` `domain`, `c`.`contact` AS `contact_full`, `c`.`network_ip`, `c`.`network_port`\
    FROM `gateways` `a` \
    LEFT JOIN `gateway_settings` `b` ON `a`.`id` = `b`.`gateway_id` AND `b`.`name` = "inbound_username" \
    LEFT JOIN `sip_registrations` `c` ON `b`.`value` = `c`.`sip_user` \
    WHERE `a`.`name`= ' .. self.database:escape(gateway_name, '"') .. ' LIMIT 1';

  local gateway = nil;
  self.database:query(sql_query, function(entry)
    require 'common.str';
    gateway = Gateway:new(self);
    gateway.record = entry;
    gateway.id = tonumber(entry.id);
    gateway.name = entry.name;
    gateway.technology = entry.technology;
    gateway.outbound = common.str.to_b(entry.outbound);
    gateway.inbound = common.str.to_b(entry.inbound);
    gateway.domain = entry.domain;
    gateway.network_ip = entry.network_ip;
    gateway.network_port = tonumber(entry.network_port) or 5060;
  end)

  if gateway then
    gateway.settings = self:config_table_get('gateway_settings', gateway.id);
  end

  return gateway;
end


function Gateway.find_by_auth_name(self, name)
  local auth_name = name:gsub('([^%a%d%._%+])', '');

  local sql_query = 'SELECT `c`.*, `a`.`value` `password`, `b`.`value` `username` \
    FROM `gateway_settings` `a` \
    INNER JOIN `gateway_settings` `b` \
    ON (`a`.`gateway_id` = `b`.`gateway_id` AND `a`.`name` = "inbound_password" AND `b`.`name` = "inbound_username" AND `b`.`value` = ' .. self.database:escape(auth_name, '"') .. ') \
    LEFT JOIN `gateways` `c` \
    ON (`a`.`gateway_id` = `c`.`id`) \
    WHERE `c`.`inbound` IS TRUE OR `c`.`outbound` IS TRUE LIMIT 1';

  local gateway = nil;
  self.database:query(sql_query, function(entry)
    require 'common.str';
    gateway = Gateway:new(self);
    gateway.record = entry;
    gateway.id = tonumber(entry.id);
    gateway.name = entry.name;
    gateway.technology = entry.technology;
    gateway.outbound = common.str.to_b(entry.outbound);
    gateway.inbound = common.str.to_b(entry.inbound);
  end)

  if gateway then
    gateway.settings = self:config_table_get('gateway_settings', gateway.id);
  end

  return gateway;
end


function Gateway.call_url(self, destination_number)
  require 'common.str';

  if common.str.blank(self.settings.dial_string) then
    if self.technology == 'sip' then
      if self.settings.inbound_username and self.settings.inbound_password and not common.str.blank(self.record.domain) then
        return 'sofia/' .. (self.settings.profile or 'gemeinschaft') .. '/' .. self.settings.inbound_username .. '%' .. self.record.domain;
      else
        return 'sofia/gateway/' .. self.GATEWAY_PREFIX .. self.id .. '/' .. tostring(destination_number);
      end
      
    elseif self.technology == 'xmpp' then
      local destination_str = tostring(destination_number);
      if self.settings.destination_domain then
        destination_str = destination_str .. '@' .. self.settings.destination_domain;
      end
      return 'dingaling/' .. self.GATEWAY_PREFIX .. self.id .. '/' .. destination_str;
    end
  else
    require 'common.array';
    return tostring(common.array.expand_variables(self.settings.dial_string, self, { destination_number = destination_number }));
  end

  return '';
end


function Gateway.authenticate(self, caller, technology)
  local sql_query = 'SELECT `c`.`name`, `c`.`id`, `a`.`value` `auth_source`, `b`.`value` `auth_pattern` \
    FROM `gateway_settings` `a` \
    INNER JOIN `gateway_settings` `b` \
    ON (`a`.`gateway_id` = `b`.`gateway_id` AND `a`.`name` = "auth_source" AND `b`.`name` = "auth_pattern" ) \
    LEFT JOIN `gateways` `c` \
    ON (`a`.`gateway_id` = `c`.`id`) \
    WHERE `c`.`inbound` IS TRUE';

  if technology then
    sql_query = sql_query .. ' AND `c`.`technology` = "' .. tostring(technology) .. '"';
  end

  local gateway = false;

  self.database:query(sql_query, function(entry)
    if caller:to_s(entry.auth_source):match(entry.auth_pattern) then
      gateway = entry;
      return;
    end
  end)

  return gateway;
end


function Gateway.profile_get(self, gateway_id)
  local sql_query = 'SELECT `value` FROM `gateway_settings` WHERE `gateway_id` = ' .. tonumber(gateway_id) .. ' AND `name` = "profile" LIMIT 1';

  return self.database:query_return_value(sql_query);
end


function Gateway.config_table_get(self, config_table, gateway_id)
  require 'common.str'

  local sql_query = 'SELECT * FROM `'.. config_table ..'` WHERE `gateway_id` = ' .. tonumber(gateway_id);

  local settings = {};
  self.database:query(sql_query, function(entry)
    local p_class_type = common.str.strip(entry.class_type):lower();
    local p_name = common.str.strip(entry.name):lower();

    if p_class_type == 'boolean' then
      settings[p_name] = common.str.to_b(entry.value);
    elseif p_class_type == 'integer' then
      settings[p_name] = common.str.to_i(entry.value);
    else
      settings[p_name] = tostring(entry.value);
    end
  end)

  return settings
end


function Gateway.parameters_build(self, gateway_id, technology)
  local settings = self:config_table_get('gateway_settings', gateway_id);

  require 'common.str'
  local parameters = {};

  if technology == 'sip' then
    parameters.realm = settings.domain;
    parameters.extension = 'auto_to_user';
    
    if common.str.blank(settings.username) then
      parameters.username = 'gateway' .. gateway_id;
      parameters.register = false;
    else
      parameters.username = settings.username;
      parameters.register = true;
    end

    if not common.str.blank(settings.register) then
      parameters.register = common.str.to_b(settings.register);
    end

    if not common.str.blank(settings.password) then
      parameters.password = settings.password;
    end

    parameters['extension-in-contact'] = true;

    if common.str.blank(settings.contact) then
      parameters['extension'] = 'gateway' .. gateway_id;
    else
      parameters['extension'] = settings.contact;
    end
  elseif technology == 'xmpp' then
    parameters.message = 'Gemeinschaft 5 by AMOOMA';
    parameters.dialplan = 'XML';
    parameters.context = 'default';
    parameters['rtp-ip'] = 'auto';
    parameters['auto-login'] = 'true';
    parameters.sasl = 'plain';
    parameters.tls = 'true';
    parameters['use-rtp-timer'] = 'true';
    parameters.vad = 'both';
    parameters.use_jingle = 'true';
    parameters['candidate-acl'] = 'wan.auto';
    parameters.name = self.GATEWAY_PREFIX .. gateway_id;
    parameters.server = settings.server;
    parameters.login = settings.login;
    parameters.password = settings.password;
    parameters.exten = settings.inbound_number or parameters.name;
  end

  for key, value in pairs(self:config_table_get('gateway_parameters', gateway_id)) do 
    parameters[key] = value; 
  end

  return parameters;
end


function Gateway.headers_get(self, header_type, gateway_id)
  gateway_id = gateway_id or self.id;

  local sql_query = 'SELECT * FROM `gateway_headers` WHERE `gateway_id` = ' .. tonumber(gateway_id) .. ' AND `header_type` = ' .. self.database:escape(header_type, '"');

  local headers = {};
  self.database:query(sql_query, function(entry)
    table.insert(headers, entry);
  end)

  return headers;
end

function Gateway.constraint_match(self, pattern, search_string)
  local success, result = pcall(string.find, tostring(search_string), tostring(pattern));

  if not success then
    self.log:error('CONSTRAINT_ERROR - table error - pattern: ', pattern, ', search_string: ', search_string);
  end

  return result;
end

function Gateway.origination_variables(self, header_type, origination_variables, variables)
  local dtmf = tostring(self.settings.dtmf_type):lower();
  if dtmf == 'inband' then
    table.insert(origination_variables,  "dtmf_type=none");
  elseif dtmf == 'none' or dtmf == 'info' then
    table.insert(origination_variables,  "dtmf_type=" .. dtmf);
  else
    table.insert(origination_variables,  "dtmf_type=rfc2833");
  end

  local headers = self:headers_get(header_type);
  self.log:debug(headers);
  for index, header in ipairs(headers) do
    local search_string = common.array.try(variables, header.constraint_source)
    if common.str.blank(header.constraint_source) or self:constraint_match(header.constraint_value, search_string) then
      if header.header_type == 'invite' then
        local origination_variable = "sip_h_" .. header.name;
        if header.name:lower() == 'from' then
          origination_variable = 'sip_from_uri';
          origination_variable = 'sip_invite_from_uri';
        elseif header.name:lower() == 'to' then
          origination_variable = 'sip_invite_to_uri';
        elseif header.name:lower() == 'invite' then
          origination_variable = 'sip_invite_req_uri';
        end
        table.insert(origination_variables,  origination_variable .. "='" .. common.array.expand_variables(header.value, variables) .. "'");
      end
    end
  end
end
