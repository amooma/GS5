-- Gemeinschaft 5 module: sip configuration class
-- (c) AMOOMA GmbH 2012
-- 

module(...,package.seeall)

Sip = {}

-- create sip configuration object
function Sip.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.database = arg.database;
  self.record = arg.record;
  return object;
end

-- find gateway by name
function Sip.find_gateway_by_name(self, name)
  require 'common.configuration_file'
  return common.configuration_file.get('/opt/freeswitch/scripts/ini/gateways.ini', name);
end

-- list sip domains
function Sip.domains(self)
  local sql_query = 'SELECT * FROM `sip_domains`';
  local sip_domains = {}

  self.database:query(sql_query, function(sip_domain)
    table.insert(sip_domains, sip_domain);
  end)

  return sip_domains;
end
