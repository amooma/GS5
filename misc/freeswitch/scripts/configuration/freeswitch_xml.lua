-- ConfigurationModule: FreeSwitchXml
--
module(...,package.seeall)

FreeSwitchXml = {}

-- Create FreeSwitchXml object
function FreeSwitchXml.new(self, object)
  object = object or {}
  setmetatable(object, self)
  self.__index = self
  return object
end

function FreeSwitchXml.nv_tag(self, name, value, tag)
  return '<' .. tostring(tag) .. ' name="' .. tostring(name) .. '" value="' .. tostring(value) .. '"/>'
end

function FreeSwitchXml.document(self, sections_xml)
  if type(sections_xml) == "string" then
    sections_xml = { sections_xml }
  elseif type(sections_xml) == "nil" then
    sections_xml = { "" }
  end

  local xml_string=
[[<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<document type="freeswitch/xml">
]] .. table.concat(sections_xml, "\n") .. [[

</document>]]

  return xml_string
end

function FreeSwitchXml.directory(self, entries_xml, domain)
   if type(entries_xml) == "string" then
    entries_xml = { entries_xml }
  elseif type(entries_xml) == "nil" then
    entries_xml = { "" }
  end

  local xml_string =
[[
<section name="directory">
<domain name="]] .. domain .. [[">
<params>
<param name="dial-string" value="${sofia_contact(${dialed_user}@${dialed_domain})}"/>
</params>
]] .. table.concat(entries_xml, "\n") .. [[

</domain>
</section>]]
  return xml_string
end

function FreeSwitchXml.group_default(self, entries_xml)
   if type(entries_xml) == "string" then
    entries_xml = { entries_xml }
  elseif type(entries_xml) == "nil" then
    entries_xml = { "" }
  end

  local xml_string =
[[
<groups>
<group name="default">
<users>
]] .. table.concat(entries_xml, "\n") .. [[

</users>
</group>
</groups>]]
  return xml_string
end

function FreeSwitchXml.user(self, user, params)
  params = params or {};

  params['password'] = user.password;
  params['vm-password'] = user.voicemail_pin;

  local variables = {
    user_context           = "default",
    gs_from_gateway        = "false",
    gs_account_id          = user.id,
    gs_account_uuid        = user.uuid,
    gs_account_type        = "SipAccount",
    gs_account_state       = user.state,
    gs_account_caller_name = user.caller_name,
    gs_account_owner_type  = user.sip_accountable_type,
    gs_account_owner_id    = user.sip_accountable_id    
  }

  local params_xml = {}
  for name, value in pairs(params) do
    params_xml[#params_xml+1] = self:nv_tag(name, value, 'param')
  end

  local variables_xml = {}
  for name, value in pairs(variables) do
    variables_xml[#variables_xml+1] = self:nv_tag(name, value, 'variable')
  end

  local xml_string =
[[
<user id="]] .. user.auth_name .. [[">
<params>
]] .. table.concat(params_xml, "\n") .. [[

</params>
<variables>
]] .. table.concat(variables_xml, "\n") .. [[

</variables>
</user>]]
  return xml_string
end

function FreeSwitchXml.gateway_user(self, user, gateway_name, auth_name)
  user.id = user.id or 0

  local params = {
    ['password']    = user.password,
  }

  local variables = {
    user_context = "default",
    gs_from_gateway = "true",
    gs_gateway_name = gateway_name,
    gs_gateway_id   = user.id
  }

  local params_xml = {}
  for name, value in pairs(params) do
    params_xml[#params_xml+1] = self:nv_tag(name, value, 'param')
  end

  local variables_xml = {}
  for name, value in pairs(variables) do
    variables_xml[#variables_xml+1] = self:nv_tag(name, value, 'variable')
  end

  local xml_string =
[[
<user id="]] .. auth_name .. [[">
<params>
]] .. table.concat(params_xml, "\n") .. [[

</params>
<variables>
]] .. table.concat(variables_xml, "\n") .. [[

</variables>
</user>]]
  return xml_string
end

function FreeSwitchXml.sofia(self, parameters, profiles_xml)
  if type(profiles_xml) == "string" then
    profiles_xml = { profiles_xml }
  elseif type(profiles_xml) == "nil" then
    profiles_xml = { "" }
  end

  local params_xml = {}
  for name, value in pairs(parameters) do
    params_xml[#params_xml+1] = self:nv_tag(name, value, 'param')
  end

  local xml_string =
[[
<section name="configuration" description="FreeSwitch configuration for Sofia Profile">
<configuration name="sofia.conf" description="Sofia SIP Configuration">
<global_settings>
]] .. table.concat(params_xml, "\n") .. [[

</global_settings>
<profiles>
]] .. table.concat(profiles_xml, "\n") .. [[

</profiles>
</configuration>
</section>]]
  return xml_string
end

function FreeSwitchXml.sofia_profile(self, profile_name, parameters, gateways_xml)
  params_xml = {}
  for name, value in pairs(parameters) do
    params_xml[#params_xml+1] = self:nv_tag(name, value, 'param')
  end

  if type(gateways_xml) == "string" then
    gateways_xml = { gateways_xml }
  elseif type(gateways_xml) == "nil" then
    gateways_xml = { "" }
  end

  local xml_string =
[[
<profile name="]] .. profile_name .. [[">
<aliases>
</aliases>
<gateways>
]] .. table.concat(gateways_xml, "\n") .. [[

</gateways>
<domains>
<domain name="all" alias="true" parse="false"/>
</domains>
<settings>
]] .. table.concat(params_xml, "\n") .. [[

</settings>
</profile>]]
  return xml_string
end

function FreeSwitchXml.gateway(self, gateway_name, parameters)
  local params_xml = {}
  if parameters then    
    for name, value in pairs(parameters) do
      params_xml[#params_xml+1] = self:nv_tag(name, value, 'param')
    end
  end

  local xml_string =
[[
<gateway name="]] .. gateway_name .. [[">
]] .. table.concat(params_xml, "\n") .. [[

</gateway>]]
  return xml_string
end

function FreeSwitchXml.conference(self, profiles_xml)
  if type(profiles_xml) == "string" then
    profiles_xml = { profiles_xml }
  elseif type(profiles_xml) == "nil" then
    profiles_xml = { "" }
  end

  local xml_string =
[[
<section name="configuration" description="FreeSwitch configuration for Sofia Profile">
<configuration name="conference.conf" description="Conference configuration">
<advertise>
</advertise>
<caller-controls>
<group name="speaker">
<control action="mute"/>
<control action="deaf mute" digits="*"/>
<control action="energy up" digits="9"/>
<control action="energy equ" digits="8"/>
<control action="energy dn" digits="7"/>
<control action="vol talk up" digits="3"/>
<control action="vol talk zero" digits="2"/>
<control action="vol talk dn" digits="1"/>
<control action="vol listen up" digits="6"/>
<control action="vol listen zero" digits="5"/>
<control action="vol listen dn" digits="4"/>
<control action="hangup" digits="#"/>
</group>
<group name="moderator">
<control action="mute" digits="0"/>
<control action="deaf mute" digits="*"/>
<control action="energy up" digits="9"/>
<control action="energy equ" digits="8"/>
<control action="energy dn" digits="7"/>
<control action="vol talk up" digits="3"/>
<control action="vol talk zero" digits="2"/>
<control action="vol talk dn" digits="1"/>
<control action="vol listen up" digits="6"/>
<control action="vol listen zero" digits="5"/>
<control action="vol listen dn" digits="4"/>
<control action="hangup" digits="#"/>
</group>
</caller-controls>
<profiles>
]] .. table.concat(profiles_xml, "\n") .. [[

</profiles>
</configuration>
</section>]]
  return xml_string
end

function FreeSwitchXml.conference_profile(self, profile_name, parameters)
  local params_xml = {}
  for name, value in pairs(parameters) do
    params_xml[#params_xml+1] = self:nv_tag(name, value, 'param')
  end

  local xml_string =
[[
<profile name="]] .. profile_name .. [[">
]] .. table.concat(params_xml, "\n") .. [[

</profile>]]
  return xml_string
end

function FreeSwitchXml.generic(self, arg)
  local params_xml = arg.params_xml or {};
  local params_tag = arg.params_tag or 'settings';
  local parameter_tag = arg.parameter_tag or 'param';
  
  if arg.parameters then
    for name, value in pairs(arg.parameters) do
      params_xml[#params_xml+1] = self:nv_tag(name, value, parameter_tag)
    end
  end

 local xml_string =
[[
<section name="configuration" description="FreeSWITCH configuration">
<configuration name="]] .. tostring(arg.name) .. [[" description="Created by FreeSwitchXml.generic">
<]] .. tostring(params_tag) .. [[>
]] .. table.concat(params_xml, "\n") .. [[

</]] .. tostring(params_tag) .. [[>
</configuration>
</section>]]
  return xml_string
end
