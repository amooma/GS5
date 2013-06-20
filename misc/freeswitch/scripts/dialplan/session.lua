-- Gemeinschaft 5 module: caller session class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

Session = {}

-- create session object
function Session.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.session = arg.session;

  if not self.session then
    return nil;
  end

  return object;
end

function Session.init_channel_variables(self)
  self.cause = "UNSPECIFIED"

  self.uuid                 = self.session:get_uuid();
  self.destination_number   = self:expand_variables(self:to_s('destination_number'));
  self.called_number        = self.destination_number;

  self.caller_id_number     = self:to_s('caller_id_number');
  self.caller_id_name       = self:to_s('caller_id_name');
  self.caller_phone_number  = self.caller_id_number;
  self.caller_phone_numbers = {self.caller_id_number};

  self.domain               = self:to_s('domain_name');
  self.gateway_name         = self:to_s('sip_gateway');
  self.from_gateway         = self:to_b('gs_from_gateway');
  if self.from_gateway then
    self.gateway_name       = self:to_s('gs_gateway_name');
  elseif self.gateway_name ~= '' then
    self.from_gateway       = true;
  end

  self.dialed_sip_user      = self:to_s('dialed_user');
  self.dialed_domain        = self:to_s('dialed_domain');

  self.account_uuid         = self:to_s('gs_account_uuid');
  self.account_type         = self:to_s('gs_account_type');
  self.sip_contact_host     = self:to_s('sip_contact_host');
  self.sip_network_ip       = self:to_s('sip_network_ip');
  self.clir                 = self:to_b('gs_clir');
  self.call_timeout         = self:to_i('gs_call_timeout');
  self.auth_account_type    = self:to_s('gs_auth_account_type');
  self.auth_account_uuid    = self:to_s('gs_auth_account_uuid');

  self.node_id              = self:to_i('sip_h_X-GS_node_id');
  self.loop_count           = self:to_i('sip_h_X-GS_loop_count');

  self.previous_destination_type    = self:to_s('gs_destination_type');
  self.previous_destination_id      = self:to_i('gs_destination_id');
  self.previous_destination_uuid    = self:to_s('gs_destination_uuid');
  self.previous_destination_owner_type    = self:to_s('gs_destination_owner_type');
  self.previous_destination_owner_id      = self:to_i('gs_destination_owner_id');
  self.previous_destination_owner_uuid    = self:to_s('gs_destination_owner_uuid');

  if self.node_id > 0 and self.node_id ~= self.local_node_id then
    self.from_node          = true;
  else
    self.from_node          = false;
  end
  self:set_variable('gs_account_node_local', not self.from_node);

  if self.from_node then
    self.account_uuid         = self:to_s('sip_h_X-GS_account_uuid');
    self.account_type         = self:to_s('sip_h_X-GS_account_type');
    self.auth_account_uuid    = self:to_s('sip_h_X-GS_auth_account_uuid');
    self.auth_account_type    = self:to_s('sip_h_X-GS_auth_account_type');
  end

  if self.auth_account_type == '' then
    self.auth_account_type   = self.account_type;
    self.auth_account_uuid   = self.account_uuid;
  end

  self.forwarding_number       = nil;
  self.forwarding_service      = nil;

  return true;
end


-- Cast channel variable to string
function Session.to_s(self, variable_name)
  require 'common.str'
  return common.str.to_s(self.session:getVariable(variable_name));
end

-- Cast channel variable to integer
function Session.to_i(self, variable_name)
  require 'common.str'
  return common.str.to_i(self.session:getVariable(variable_name));
end

-- Cast channel variable to boolean
function Session.to_b(self, variable_name)
  require 'common.str'
  return common.str.to_b(self.session:getVariable(variable_name));
end

-- Split channel variable to table
function Session.to_a(self, variable_name)
  require 'common.str'
  return common.str.to_a(self.session:getVariable(variable_name));
end

-- Check if session is active
function Session.ready(self, command, parameters)
  return self.session:ready();
end

-- Wait milliseconds
function Session.sleep(self, milliseconds)
  return self.session:sleep(milliseconds);
end

-- Execute command
function Session.execute(self, command, parameters)
  parameters = parameters or '';
  self.session:execute(command, parameters);
end

-- Execute and return result
function Session.result(self, command_line)
  self.session:execute('set', 'result=${' .. command_line .. '}');
  return self.session:getVariable('result');
end

-- Set cause code
function Session.set_cause(self, cause)
  self.cause = cause
end

-- Set channel variable
function Session.set_variable(self, name, value)
  self.session:setVariable(name, tostring(value));
end

-- Set and export channel variable
function Session.export_variable(self, name, value)
  self.session:execute('export', tostring(name) .. '=' .. tostring(value));
end

-- Set SIP header
function Session.set_header(self, name, value)
  self.session:setVariable('sip_h_' .. name, tostring(value));
end

-- Hangup a call
function Session.hangup(self, cause)
  return self.session:hangup(cause);
end

-- Respond a call
function Session.respond(self, code, text)
  self.session:execute('respond', tostring(code) .. ' ' .. text);
  return self.session:hangupCause();
end

-- Answer a call
function Session.answer(self)
  return self.session:answer();
end

-- Is answered?
function Session.answered(self)
  return self.session:answered();
end


function Session.intercept(self, uid)
  self.session:execute("intercept", uid);
end

function Session.send_display(self, ... )
  self:execute('send_display', table.concat( arg, '|'));
end

-- Set caller ID
function Session.set_caller_id(self, number, name)
  if number then
    self.caller_id_number = tostring(number);
    self.session:setVariable('effective_caller_id_number', tostring(number))
  end
  if name then
    self.caller_id_name = tostring(name);
    self.session:setVariable('effective_caller_id_name', tostring(name))
  end
end

-- Set callee ID
function Session.set_callee_id(self, number, name)
  if number ~= nil then
    self.callee_id_number = tostring(number);
    self.session:execute('export', 'effective_callee_id_number=' .. number);
  end
  if name ~= nil then
    self.callee_id_name = tostring(name);
    self.session:execute('export', 'effective_callee_id_name=' .. name);
  end
end


function Session.set_auth_account(self, auth_account)
  if auth_account then
    self:set_variable('gs_auth_account_type', auth_account.class);
    self:set_variable('gs_auth_account_id', auth_account.id);
    self:set_variable('gs_auth_account_uuid', auth_account.uuid);
  end

  return auth_account;
end


function Session.expand_variables(self, line)
  return (line:gsub('{([%a%d_-]+)}', function(captured)
    return self.session:getVariable(captured) or '';
  end))
end


function Session.playback(self, file)
  self.session:streamFile(file);
end
