-- Gemeinschaft 5 dynamic freeswitch configuration
-- (c) AMOOMA GmbH 2012-2013
-- 

function nodes(database, local_node_id)
  require 'configuration.simple_xml'
  local xml = configuration.simple_xml.SimpleXml:new();

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
      gateways_xml = gateways_xml .. xml:element{
        'gateway',
        name = node_record.name,
        xml:from_hash('param', node_parameters, 'name', 'value'),
      };
    end
  end

  return gateways_xml;
end


function sofia_gateways(database, profile_name)
  require 'configuration.simple_xml'
  local xml = configuration.simple_xml.SimpleXml:new();

  require 'common.str'

  require 'common.gateway'
  local gateway_class = common.gateway.Gateway:new{ log = log, database = database};
  local gateways = gateway_class:list('sip');

  local gateways_xml = '';
  for index=1, #gateways do
    local gateway = gateways[index];
    local gateway_profile = gateway_class:profile_get(gateway.id);
    if tostring(gateway_profile) == profile_name or (profile_name == 'gemeinschaft' and common.str.blank(gateway_profile)) then
      log:debug('SIP_GATEWAY - name: ', gateway.name);
      local parameters = gateway_class:parameters_build(gateway.id, 'sip');

      gateways_xml = gateways_xml .. xml:element{
        'gateway',
        name = gateway_class.GATEWAY_PREFIX .. gateway.id,
        xml:from_hash('param', parameters, 'name', 'value'),
      };
    end
  end

  return gateways_xml;
end


function profile(database, sofia_ini, profile_name, index, domains, node_id)
  require 'configuration.simple_xml'
  local xml = configuration.simple_xml.SimpleXml:new();

  local profile_template = sofia_ini['profile'] or {};
  local parameters = sofia_ini['profile:' .. profile_name] or {};

  for key, value in pairs(profile_template) do
    parameters[key] = parameters[key] or value;
  end

  if not parameters then
    log:error('SOFIA_PROFILE ', index,' - name: ', profile_name, ' - no parameters');
    return '';
  end

  if tostring(parameters['odbc-dsn']) == 'default' then
    parameters['odbc-dsn'] = 'gemeinschaft:' .. tostring(database.user_name) .. ':' .. tostring(database.password);
  end

  parameters['username'] = parameters['username'] or 'Gemeinschaft';
  parameters['user-agent-string'] = parameters['user-agent-string'] or 'Gemeinschaft';

  -- set local bind address
  if domains[index] then
    parameters['sip-ip'] = domains[index]['host'];
    parameters['rtp-ip'] = domains[index]['host'];
    parameters['force-register-domain'] = domains[index]['host'];
    parameters['force-subscription-domain'] = domains[index]['host'];
    parameters['force-register-db-domain'] = domains[index]['host'];
    log:debug('SOFIA_PROFILE ', index,' - name: ', profile_name, ', domain: ', domains[index]['host'], ',  sip_bind: ', parameters['sip-ip'], ':', parameters['sip-port']);
  else
    log:debug('SOFIA_PROFILE ', index,' - name: ', profile_name, ' - no domains');
  end

  local gateways_xml = sofia_gateways(database, profile_name);

  if index == 1 then
    gateways_xml = gateways_xml .. nodes(database, node_id);
  end

  local profile_xml = xml:element{
    'profile',
    name = profile_name,
    xml:element{
      'gateways',
      gateways_xml,
    },
    xml:element{
      'domains',
      xml:element{
        'domain',
        name = 'all',
        alias = 'true',
        parse = 'false',
      },
    },
    xml:element{
      'settings',
      xml:from_hash('param', parameters, 'name', 'value'),
    },
  };

  return profile_xml;
end


-- generate sofia.conf
function conf_sofia(database)
  require 'configuration.simple_xml'
  local xml = configuration.simple_xml.SimpleXml:new();

  require 'common.configuration_table'
  local sofia_profile = "gemeinschaft";

  local sofia_ini = common.configuration_table.get(database, 'sofia');
  local dialplan_parameters = common.configuration_table.get(database, 'dialplan', 'parameters');

  local local_node_id = tonumber(dialplan_parameters.node_id) or 1;
  
  require 'configuration.sip'
  local domains = configuration.sip.Sip:new{ log = log, database = database}:domains();

  local sofia_profiles = {};
  for profile_name, index in pairs(sofia_ini.profiles) do
    if tonumber(index) and tonumber(index) > 0  then
      sofia_profiles[index] = profile_name;
    end
  end

  local sofia_profiles_xml = '';
  for index, profile_name in ipairs(sofia_profiles) do
    if tonumber(index) and tonumber(index) > 0  then
      sofia_profiles_xml = sofia_profiles_xml .. profile(database, sofia_ini, profile_name, tonumber(index), domains, local_node_id);
    end
  end

  XML_STRING = xml:element{
    'document', 
    ['type'] = 'freeswitch/xml',
    xml:element{
      'section',
      name = 'configuration',
      description = 'Gemeinschaft 5 FreeSWITCH configuration',
      xml:element{
        'configuration',
        name = 'sofia.conf',
        description = 'Sofia configuration',
        xml:element{
          'global_settings',
          xml:from_hash('param', sofia_ini.parameters, 'name', 'value'),
        },
        xml:element{
          'profiles',
          sofia_profiles_xml,
        },
      },
    },
  };

end

function conf_conference(database)
  require 'configuration.simple_xml'
  local xml = configuration.simple_xml.SimpleXml:new();

  require 'common.configuration_table'
  local config = common.configuration_table.get(database, 'conferences');
  local profiles = nil;

  local event_name = params:getHeader("Event-Name")
  if event_name == 'COMMAND' then
    local conf_name    = params:getHeader('conf_name');
    local profile_name = params:getHeader('profile_name');

    if conf_name then
      require 'common.conference'
      conference = common.conference.Conference:new{log=log, database=database}:find_by_id(common.str.to_i(conf_name));
      if conference then
        log:debug('CONFIG_CONFERENCE ', conf_name, ' name: ', conference.record.name, ', profile: ', profile_name);
        config.parameters['caller-id-name'] = conference.record.name or '';
        profiles = xml:element{
          'profiles',
          xml:element{
            'profile',
            name = profile_name,
            xml:from_hash('param', config.parameters, 'name', 'value'),
          },
        };
      else
        log:error('CONFIG_CONFERENCE ', conf_name, ' - conference not found');
      end
    else
      log:notice('CONFIG_CONFERENCE - no conference name');
    end
  else
    log:debug('CONFIG_CONFERENCE ', conf_name, ' - event: ', event_name);
  end

  XML_STRING = xml:element{
    'document', 
    ['type'] = 'freeswitch/xml',
    xml:element{
      'section',
      name = 'configuration',
      description = 'Gemeinschaft 5 FreeSWITCH configuration',
      xml:element{
        'configuration',
        name = 'conference.conf',
        description = 'Conference configuration',
        xml:element{
          'caller-controls',
          xml:element{
            'group',
            name = 'speaker',
            xml:from_hash('control', config.controls_speaker, 'action', 'digits'),
          },
          xml:element{
            'group',
            name = 'moderator',
            xml:from_hash('control', config.controls_moderator, 'action', 'digits'),
          },
        },
        profiles,
      },
    },
  };
end

function conf_voicemail(database)
  require 'configuration.simple_xml'
  local xml = configuration.simple_xml.SimpleXml:new();

  require 'common.configuration_table';
  local parameters = common.configuration_table.get(database, 'voicemail', 'parameters');

  if tostring(parameters['odbc-dsn']) == 'default' then
    parameters['odbc-dsn'] = 'gemeinschaft:' .. tostring(database.user_name) .. ':' .. tostring(database.password);
  end

  XML_STRING = xml:element{
    'document', 
    ['type'] = 'freeswitch/xml',
    xml:element{
      'section',
      name = 'configuration',
      description = 'Gemeinschaft 5 FreeSWITCH configuration',
      xml:element{
        'configuration',
        name = 'voicemail.conf',
        description = 'Voicemail configuration',
        xml:element{
          'profiles',
          xml:element{
            'profile',
            name = 'default',
            xml:from_hash('param', parameters, 'name', 'value'),
          },
        },
      },
    },
  };
end

function conf_post_switch(database)
  require 'configuration.simple_xml'
  local xml = configuration.simple_xml.SimpleXml:new();

  require 'common.configuration_table';
  local parameters = common.configuration_table.get(database, 'post_load_switch', 'settings');

  XML_STRING = xml:element{
    'document', 
    ['type'] = 'freeswitch/xml',
    xml:element{
      'section',
      name = 'configuration',
      description = 'Gemeinschaft 5 FreeSWITCH configuration',
      xml:element{
        'configuration',
        name = 'post_load_switch.conf',
        description = 'Switch configuration',
        xml:element{
          'settings',
          xml:from_hash('param', parameters, 'name', 'value'),
        },
      },
    },
  };
end


function dingaling_profiles(database)
  local TECHNOLOGY = 'xmpp';
  require 'common.str'
  require 'configuration.simple_xml'
  local xml = configuration.simple_xml.SimpleXml:new();

  require 'common.gateway'
  local gateway_class = common.gateway.Gateway:new{ log = log, database = database};
  local gateways = gateway_class:list(TECHNOLOGY);

  local gateways_xml = '';
  for index=1, #gateways do
    local gateway = gateways[index];
    local gateway_profile = gateway_class:profile_get(gateway.id);   
    log:debug('XMPP_GATEWAY - name: ', gateway.name);
    local parameters = gateway_class:parameters_build(gateway.id, TECHNOLOGY);

    gateways_xml = gateways_xml .. xml:element{
      'profile',
      ['type'] = 'client',
      xml:from_hash('param', parameters, 'name', 'value'),
    };
  end

  return gateways_xml;
end


function conf_dingaling(database)
  require 'configuration.simple_xml'
  local xml = configuration.simple_xml.SimpleXml:new();

  require 'common.configuration_table';
  local parameters = common.configuration_table.get(database, 'dingaling', 'parameters') or {};

  local profiles_xml = dingaling_profiles(database) or '';

  XML_STRING = xml:element{
    'document', 
    ['type'] = 'freeswitch/xml',
    xml:element{
      'section',
      name = 'configuration',
      description = 'Gemeinschaft 5 FreeSWITCH configuration',
      xml:element{
        'configuration',
        name = 'dingaling.conf',
        description = 'Jingle endpoint configuration',
        xml:element{
          'settings',
          xml:from_hash('param', parameters, 'name', 'value'),
        },
      profiles_xml,  
      },
    },
  };
end


function directory_sip_account(database)
  require 'common.str';
  require 'configuration.simple_xml'
  local xml = configuration.simple_xml.SimpleXml:new();

  local key       = params:getHeader('key');
  local auth_name = params:getHeader('user');
  local domain    = params:getHeader('domain');
  local purpose   = params:getHeader('purpose');

  local user_xml = nil;

  if not common.str.blank(auth_name) then
    require 'common.sip_account'
    local sip_account = common.sip_account.SipAccount:new{ log = log, database = database}:find_by_auth_name(auth_name);

    require 'common.configuration_table'
    local user_parameters = common.configuration_table.get(database, 'sip_accounts', 'parameters');
          
    if sip_account ~= nil then
      user_parameters['password'] = sip_account.record.password;
      user_parameters['vm-password'] = sip_account.record.voicemail_pin;

      local user_variables = {
        user_context           = "default",
        gs_from_gateway        = "false",
        gs_account_id          = sip_account.record.id,
        gs_account_uuid        = sip_account.record.uuid,
        gs_account_type        = "SipAccount",
        gs_account_state       = sip_account.record.state,
        gs_account_caller_name = sip_account.record.caller_name,
        gs_account_owner_type  = sip_account.record.sip_accountable_type,
        gs_account_owner_id    = sip_account.record.sip_accountable_id    
      }

      if tostring(purpose) == 'publish-vm' then
        log:debug('DIRECTORY_SIP_ACCOUNT - purpose: VoiceMail, auth_name: ', sip_account.record.auth_name, ', caller_name: ', sip_account.record.caller_name, ', domain: ', domain);
        user_xml = xml:element{
          'groups',
          xml:element{
            'group',
            name = 'default',
            xml:element{
              'users',
              xml:element{  
                'user',
                id = sip_account.record.auth_name,
                xml:element{
                  'params',
                  xml:from_hash('param', user_parameters, 'name', 'value'),
                },
                xml:element{
                  'variables',
                  xml:from_hash('variable', user_variables, 'name', 'value'),
                },
              },
            },
          },
        };
      else
        log:debug('DIRECTORY_SIP_ACCOUNT - auth_name: ', sip_account.record.auth_name, ', caller_name: ', sip_account.record.caller_name, ', domain: ', domain);
        
        user_xml = xml:element{
          'user',
          id = sip_account.record.auth_name,
          xml:element{
            'params',
            xml:from_hash('param', user_parameters, 'name', 'value'),
          },
          xml:element{
            'variables',
            xml:from_hash('variable', user_variables, 'name', 'value'),
          },
        };
      end
    else
      require 'common.gateway'
      local sip_gateway = common.gateway.Gateway:new{ log = log, database = database }:find_by_auth_name(auth_name);

      if sip_gateway then
        log:debug('DIRECTORY_GATEWAY - name: ', sip_gateway.name, ', auth_name: ', auth_name);

        local user_variables = {
          user_context = 'default',
          gs_from_gateway   = 'true',
          gs_gateway_name   = sip_gateway.name,
          gs_gateway_id     = sip_gateway.id,
          gs_gateway_domain = domain,
        }

        user_xml = xml:element{
          'user',
          id = auth_name,
          xml:element{
            'params',
            xml:element{
              'param',
              password = sip_gateway.record.password,
            }
          },
          xml:element{
            'variables',
            xml:from_hash('variable', user_variables, 'name', 'value'),
          },
        };
      else
        log:debug('DIRECTORY_SIP_ACCOUNT - neither a sip account nor a gateway found by SIP user name: ', auth_name, ', domain: ', domain);
        -- fake sip_account configuration
        user_parameters['password'] = tostring(math.random(0, 65534));
        user_parameters['vm-password'] = '';

        user_xml = xml:element{
          'user',
          id = auth_name,
          xml:element{
            'params',
            xml:from_hash('param', user_parameters, 'name', 'value'),
          },
        };
      end
    end
  elseif tostring(XML_REQUEST.key_name) == 'name' and tostring(XML_REQUEST.key_value) ~= '' then
    log:debug('DOMAIN_DIRECTORY - domain: ', XML_REQUEST.key_value);
    XML_STRING = xml:document(xml:directory(nil, XML_REQUEST.key_value));
  end

  XML_STRING = xml:element{
    'document', 
    ['type'] = 'freeswitch/xml',
    xml:element{
      'section',
      name = 'directory',
      xml:element{
        'domain',
        name = domain,
        xml:element{
          'params',
          xml:element{
            'param',
            name = 'dial-string',
            value = '${sofia_contact(${dialed_user}@${dialed_domain})}',
          },
        },
        user_xml,
      },
    },
  };  
end


local log_identifier = XML_REQUEST.key_value or 'CONFIG';

-- set logger
require 'common.log'
log = common.log.Log:new();
log.prefix = '#C# [' .. log_identifier .. '] ';

-- return a valid xml document
require 'configuration.simple_xml'
local xml = configuration.simple_xml.SimpleXml:new();
XML_STRING = xml:element{
  'document', 
  ['type'] = 'freeswitch/xml',
};

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
  elseif XML_REQUEST.key_value == "dingaling.conf" then
    conf_dingaling(database);  
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
