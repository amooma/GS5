-- Gemeinschaft 5 dynamic freeswitch configuration
-- (c) AMOOMA GmbH 2012
-- 

function nodes(database, local_node_id)
  local gateways_xml = '';

  require 'common.node'
  for node_id, node_record in pairs(common.node.Node:new{log=log, database=database}:all()) do
    if node_id ~= local_node_id then
      local node_parameters = {}
      node_parameters['username'] = node_record.name;
      node_parameters['password'] = 'gemeinschaft';
      node_parameters['proxy'] = node_record.ip_address;
      node_parameters['register'] = 'false';
      log:debug('NODE_GATEWAY ', node_record.id, ' - name: ', node_record.name, ', address: ', node_record.ip_address);
      gateways_xml = gateways_xml .. xml:gateway(node_record.name, node_parameters);
    end
  end

  return gateways_xml;
end

function gateways(profile_name)
  require 'common.configuration_file'
  local gateways_xml = '';
  local gateways  = common.configuration_file.get('/opt/freeswitch/scripts/ini/gateways.ini', false);

  if not gateways then
    return '';
  end

  for sofia_gateway, gateway_parameters in pairs(gateways) do
    if tostring(gateway_parameters.profile) == profile_name then
      log:debug('GATEWAY - name: ', sofia_gateway, ', address: ', gateway_parameters.proxy);
      gateways_xml = gateways_xml .. xml:gateway(sofia_gateway, gateway_parameters);
    end
  end

  return gateways_xml;
end

function profile(database, sofia_ini, profile_name, index, domains, node_id)
  local profile_parameters = sofia_ini['profile:' .. profile_name];

  if not profile_parameters then
    log:error('SOFIA_PROFILE ', index,' - name: ', profile_name, ' - no parameters');
    return '';
  end

  if tostring(profile_parameters['odbc-dsn']) == 'default' then
    profile_parameters['odbc-dsn'] = 'gemeinschaft:' .. tostring(database.user_name) .. ':' .. tostring(database.password);
  end

  -- set local bind address
  if domains[index] then
    profile_parameters['sip-ip'] = domains[index]['host'];
    profile_parameters['rtp-ip'] = domains[index]['host'];
    profile_parameters['force-register-domain'] = domains[index]['host'];
    profile_parameters['force-subscription-domain'] = domains[index]['host'];
    profile_parameters['force-register-db-domain'] = domains[index]['host'];
    log:debug('SOFIA_PROFILE ', index,' - name: ', profile_name, ', domain: ', domains[index]['host'], ',  sip_bind: ', profile_parameters['sip-ip'], ':', profile_parameters['sip-port']);
  else
    log:error('SOFIA_PROFILE ', index,' - name: ', profile_name, ' - no domains');
  end

  local gateways_xml = gateways(profile_name);

  if index == 1 then
    gateways_xml = gateways_xml .. nodes(database, node_id);
  end

  return xml:sofia_profile(profile_name, profile_parameters, gateways_xml);
end

-- generate sofia.conf
function conf_sofia(database)
  require 'common.configuration_table'
  local sofia_profile = "gemeinschaft";

  local sofia_ini = common.configuration_table.get(database, 'sofia');
  local dialplan_parameters = common.configuration_table.get(database, 'dialplan', 'parameters');

  local local_node_id = tonumber(dialplan_parameters.node_id) or 1;
  
  require 'configuration.sip'
  local domains = configuration.sip.Sip:new{ log = log, database = database}:domains();

  sofia_profiles_xml = '';
  for profile_name, index in pairs(sofia_ini.profiles) do
    if tonumber(index) and tonumber(index) > 0  then
      sofia_profiles_xml = sofia_profiles_xml .. profile(database, sofia_ini, profile_name, tonumber(index), domains, local_node_id);
    end
  end

  XML_STRING = xml:document(xml:sofia(sofia_ini.parameters, sofia_profiles_xml))
end

function conf_conference(database)
  require 'common.configuration_table'
  
  local config = common.configuration_table.get(database, 'conferences');
  XML_STRING = xml:document(xml:conference(nil, config.controls_speaker, config.controls_moderator));

  local event_name = params:getHeader("Event-Name")
  if event_name == 'COMMAND' then
    local conf_name    = params:getHeader('conf_name');
    local profile_name = params:getHeader('profile_name');

    if conf_name then
      require 'common.conference'
      conference = common.conference.Conference:new{log=log, database=database}:find_by_id(conf_name);
      if conference then
        log:debug('CONFIG_CONFERENCE ', conf_name, ' name: ', conference.record.name, ', profile: ', profile_name);
        config.parameters['caller-id-name'] = conference.record.name or '';
        XML_STRING = xml:document(xml:conference(xml:conference_profile(profile_name, config.parameters), config.controls_speaker, config.controls_moderator));
      else
        log:error('CONFIG_CONFERENCE ', conf_name, ' - conference not found');
      end
    else
      log:notice('CONFIG_CONFERENCE - no conference name');
    end
  else
    log:debug('CONFIG_CONFERENCE ', conf_name, ' - event: ', event_name);
  end
end

function conf_voicemail(database)
  require 'common.configuration_table';
  local parameters = common.configuration_table.get(database, 'voicemail', 'parameters');

  if tostring(parameters['odbc-dsn']) == 'default' then
    parameters['odbc-dsn'] = 'gemeinschaft:' .. tostring(database.user_name) .. ':' .. tostring(database.password);
  end

  local params_xml = {};
  for name, value in pairs(parameters) do
    params_xml[#params_xml+1] = xml:tag{ _name = 'param', name = name, value = value };
  end

  XML_STRING = xml:document(
    xml:tag{
      _name = 'section',
      name = 'configuration',
      description = 'Gemeinschaft 5 FreeSWITCH configuration',
      _data = xml:tag{
        _name = 'configuration',
        name = 'voicemail.conf',
        description = 'Voicemail configuration',
        _data = xml:tag{
          _name = 'profiles',
          _data = xml:tag{
            _name = 'profile',
            name = 'default',
            _data = table.concat(params_xml, '\n'),
          },
        },
      },
    }
  );
end

function conf_post_switch(database)
  require 'common.configuration_table';
  local parameters = common.configuration_table.get(database, 'post_load_switch', 'settings');

  XML_STRING = xml:document(xml:generic{name = 'post_load_switch.conf', parameters = parameters});
end


function directory_sip_account(database)
  local key       = params:getHeader('key');
  local auth_name = params:getHeader('user');
  local domain    = params:getHeader('domain');
  local purpose   = params:getHeader('purpose');

  if auth_name and  auth_name ~= '' then
    -- sip account or gateway
    if string.len(auth_name) > 3 and auth_name:sub(1, 3) == 'gw+' then
      local gateway_name = auth_name:sub(4);
      domain = domain or freeswitch.API():execute('global_getvar', 'domain');
      require 'configuration.sip'
      log:notice('DATABASE: ', database);
      local sip_gateway = configuration.sip.Sip:new{ log = log, database = database}:find_gateway_by_name(gateway_name);
      if sip_gateway ~= nil and next(sip_gateway) ~= nil then
        log:debug('DIRECTORY_GATEWAY - name: ', gateway_name, ', auth_name: ', auth_name);
        XML_STRING = xml:document(xml:directory(xml:gateway_user(sip_gateway, gateway_name, auth_name), domain));
      else
        log:debug('DIRECTORY_GATEWAY - gateway not found - name: ', gateway_name, ', auth_name: ', auth_name);
      end
    else
      require 'common.configuration_table'
      local user_params = common.configuration_table.get(database, 'sip_accounts', 'parameters');

      require 'common.sip_account'
      local sip_account = common.sip_account.SipAccount:new{ log = log, database = database}:find_by_auth_name(auth_name, domain);
      if sip_account ~= nil then
        if tostring(purpose) == 'publish-vm' then
          log:debug('DIRECTORY_SIP_ACCOUNT - purpose: VoiceMail, auth_name: ', sip_account.record.auth_name, ', caller_name: ', sip_account.record.caller_name, ', domain: ', domain);
          XML_STRING = xml:document(xml:directory(xml:group_default(xml:user(sip_account.record, user_params)), domain));
        else
          log:debug('DIRECTORY_SIP_ACCOUNT - auth_name: ', sip_account.record.auth_name, ', caller_name: ', sip_account.record.caller_name, ', domain: ', domain);
          XML_STRING = xml:document(xml:directory(xml:user(sip_account.record, user_params), domain));
        end
      else
        log:debug('DIRECTORY_SIP_ACCOUNT - sip account not found - auth_name: ', auth_name, ', domain: ', domain);
        -- fake sip_account configuration
        sip_account = {
              auth_name             = auth_name,
              id                    = 0,
              uuid                  = '',
              password              = tostring(math.random(0, 65534)),
              voicemail_pin         = '',
              state                 = 'inactive',
              caller_name           = '',
              sip_accountable_type  = 'none',
              sip_accountable_id    = 0,   
        }
        XML_STRING = xml:document(xml:directory(xml:user(sip_account, user_params), domain))
      end
    end
  elseif tostring(XML_REQUEST.key_name) == 'name' and tostring(XML_REQUEST.key_value) ~= '' then
    log:debug('DOMAIN_DIRECTORY - domain: ', XML_REQUEST.key_value);
    XML_STRING = xml:document(xml:directory(nil, XML_REQUEST.key_value));
  end
end


local log_identifier = XML_REQUEST.key_value or 'CONFIG';

-- set logger
require 'common.log'
log = common.log.Log:new();
log.prefix = '#C# [' .. log_identifier .. '] ';

-- return a valid xml document
require 'configuration.freeswitch_xml'
xml = configuration.freeswitch_xml.FreeSwitchXml:new();
XML_STRING = xml:document();

local database = nil;

-- log:debug('CONFIG_REQUEST section: ', XML_REQUEST.section, ', tag: ', XML_REQUEST.tag_name, ', key: ', XML_REQUEST.key_value);

if XML_REQUEST.section == 'configuration' and XML_REQUEST.tag_name == 'configuration' then
  -- database connection
  require 'common.database'
  database = common.database.Database:new{ log = log }:connect();
  if database:connected() == false then
    log:error('CONFIG_REQUEST - cannot connect to Gemeinschaft database');
    return false;
  end

  if XML_REQUEST.key_value == 'sofia.conf' then
    conf_sofia(database);
  elseif XML_REQUEST.key_value == "conference.conf" then
    conf_conference(database);
  elseif XML_REQUEST.key_value == "voicemail.conf" then
    conf_voicemail(database);
  elseif XML_REQUEST.key_value == "post_load_switch.conf" then
    conf_post_switch(database);
  end
elseif XML_REQUEST.section == 'directory' and XML_REQUEST.tag_name == '' then
  log:debug('SIP_ACCOUNT_DIRECTORY - initialization phase');
elseif XML_REQUEST.section == 'directory' and XML_REQUEST.tag_name == 'domain' then
  if params == nil then
    log:error('SIP_ACCOUNT_DIRECTORY - no parameters');
    return false;
  end
 
  require 'common.database'
  database = common.database.Database:new{ log = log }:connect();
  if not database:connected() then
    log:error('CONFIG_REQUEST - cannot connect to Gemeinschaft database');
    return false;
  end
  directory_sip_account(database);
else
  log:error('CONFIG_REQUEST - no configuration handler, section: ', XML_REQUEST.section, ', tag: ', XML_REQUEST.tag_name);
end

-- ensure database handler is released on exit
if database then
  database:release();
end
