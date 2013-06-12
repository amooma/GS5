-- Gemeinschaft 5 module: sip call class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall);

SipCall = {}

-- Create SipCall object
function SipCall.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.session = arg.session;
  self.record = arg.record;
  self.database = arg.database;
  self.domain = arg.domain;
  self.caller = arg.caller;
  self.on_answer = arg.on_answer;
  self.calling_object = arg.calling_object;
  return object;
end


function SipCall.wait_answer(self, caller_session, callee_session, timeout, start_time)
  if caller_session:ready() and callee_session:ready() then
    callee_session:waitForAnswer(caller_session);
  end

  while true do
    if not caller_session:ready() then
      return 'ORIGINATOR_CANCEL';
    elseif not callee_session:ready() then
      return 'UNSPECIFIED';
    elseif (os.time() - start_time) > timeout then
      return 'NO_ANSWER';
    elseif callee_session:answered() then
      return 'SUCCESS';
    end
    
    self.caller:sleep(500);
  end
end


function SipCall.wait_hangup(self, caller_session, callee_session)
  local hangup_on = {
    CS_HANGUP  = true,
    CS_DESTROY = true,
  }

  while true do
    local state_caller = caller_session:getState();
    local state_callee = callee_session:getState();
    if hangup_on[state_caller] or hangup_on[state_callee] then
      break;
    end
    caller_session:sleep(500);
  end
end


function SipCall.call_waiting_busy(self, sip_account)
  require 'common.str'
  if common.str.to_b(sip_account.record.call_waiting) then
    self.log:info('CALL_WAITING - status: enabled');
    return false;
  else
    local state = sip_account:call_state();
    self.log:info('CALL_WAITING - status: disabled, sip_account state: ', state);
    return state;
  end
end


function SipCall.fork(self, destinations, arg )
  local dial_strings = {};
  local pickup_groups = {};

  require 'common.sip_account'
  require 'common.str'

  local sip_account_class = common.sip_account.SipAccount:new{ log = self.log, database = self.database };

  local call_result = { code = 404, phrase = 'No destination' };
  local some_destinations_busy = false;

  for index, destination in ipairs(destinations) do
    local origination_variables = { 'gs_fork_index=' .. index }

    self.log:info('FORK ', index, '/', #destinations, ' - ', destination.type, '=', destination.id, '/', destination.uuid, '@', destination.node_id, ', number: ', destination.number);
    
    if not common.str.to_b(arg.update_callee_display) then
      table.insert(origination_variables, 'ignore_display_updates=true');
    end

    if not destination.node_local or destination.type == 'node' then
      require 'common.node'
      local node = nil;

      if not destination.node_local then
        node = common.node.Node:new{ log = self.log, database = self.database }:find_by_id(destination.node_id);
      else
        node = common.node.Node:new{ log = self.log, database = self.database }:find_by_id(destination.id);
      end
      if node then
        table.insert(origination_variables, 'sip_h_X-GS_node_id=' .. self.caller.local_node_id);
        table.insert(origination_variables, 'sip_h_X-GS_account_uuid=' .. tostring(self.caller.account_uuid));
        table.insert(origination_variables, 'sip_h_X-GS_account_type=' .. tostring(self.caller.account_type));
        table.insert(origination_variables, 'sip_h_X-GS_auth_account_type=' .. tostring(self.caller.auth_account_type));
        table.insert(origination_variables, 'sip_h_X-GS_auth_account_uuid=' .. tostring(self.caller.auth_account_uuid));
        table.insert(origination_variables, 'sip_h_X-GS_loop_count=' .. tostring(self.caller.loop_count));
        table.insert(origination_variables, 'sip_h_X-GS_clir=' .. tostring(self.caller.clir));
        table.insert(dial_strings, '[' .. table.concat(origination_variables , ',') .. ']sofia/gateway/' .. node.record.name .. '/' .. destination.number);
      end
    elseif destination.type == 'sipaccount' then
      local callee_id_params = '';
      local sip_account = sip_account_class:find_by_id(destination.id);
      if not sip_account then
        self.log:notice('FORK - sip_account not found - sip_account=', destination.id);
      elseif common.str.blank(sip_account.record.profile_name) or common.str.blank(sip_account.record.sip_host) then
        call_result = { code = 480, phrase = 'User offline', disposition = 'USER_NOT_REGISTERED' };
      else
        local call_waiting = self:call_waiting_busy(sip_account);
        if not call_waiting then
          local caller_id_number = destination.caller_id_number or self.caller.caller_id_number;
          local caller_id_name = destination.caller_id_name or self.caller.caller_id_name;
          destinations[index].numbers = sip_account:phone_numbers();

          if not arg.callee_id_name then
            table.insert(origination_variables, "effective_callee_id_name='" .. sip_account.record.caller_name .. "'");
          end
          if not arg.callee_id_number then
            table.insert(origination_variables, "effective_callee_id_number='" .. destination.number .. "'");
          end
          if destination.alert_info then
            table.insert(origination_variables, "alert_info='" .. destination.alert_info .. "'");
          end
          if destination.account then
            table.insert(origination_variables, "gs_account_type='" .. common.str.to_s(destination.account.class) .. "'");
            table.insert(origination_variables, "gs_account_id='" .. common.str.to_i(destination.account.id) .. "'");
            table.insert(origination_variables, "gs_account_uuid='" .. common.str.to_s(destination.account.uuid) .. "'");
          end
          if self.caller.auth_account then
            table.insert(origination_variables, "gs_auth_account_type='" .. common.str.to_s(self.caller.auth_account.class) .. "'");
            table.insert(origination_variables, "gs_auth_account_id='" .. common.str.to_i(self.caller.auth_account.id) .. "'");
            table.insert(origination_variables, "gs_auth_account_uuid='" .. common.str.to_s(self.caller.auth_account.uuid) .. "'");
          end

          if self.caller.clir then
            caller_id_number = self.caller.anonymous_number or 'anonymous';
            caller_id_name = self.caller.anonymous_name or 'Anonymous';
            table.insert(origination_variables, "origination_caller_id_number='" .. caller_id_number .. "'");
            table.insert(origination_variables, "origination_caller_id_name='" .. caller_id_name .. "'");
            table.insert(origination_variables, "sip_h_Privacy='id'");
          end

          self.log:info('FORK ', index, '/', #destinations, ' - caller_id: "', caller_id_name, '" <', caller_id_number, '>, privacy: ', self.caller.clir);

          table.insert(dial_strings, '[' .. table.concat(origination_variables , ',') .. ']sofia/' .. sip_account.record.profile_name .. '/' .. sip_account.record.auth_name .. '%' .. sip_account.record.sip_host);
          if destination.pickup_groups and #destination.pickup_groups > 0 then
            for key=1, #destination.pickup_groups do
              pickup_groups[destination.pickup_groups[key]] = true;
            end
          end
        else 
          some_destinations_busy = true;
          call_result = { code = 486, phrase = 'User busy', disposition = 'USER_BUSY' };
        end
      end
    elseif destination.type == 'gateway' then
      require 'common.gateway'
      local gateway = common.gateway.Gateway:new{ log = self.log, database = self.database}:find_by_id(destination.id);

      if gateway and gateway.outbound then
        local asserted_identity = tostring(gateway.settings.asserted_identity);
        local asserted_identity_clir = tostring(gateway.settings.asserted_identity);
        local caller_id_number = destination.caller_id_number or self.caller.caller_id_number;
        local caller_id_name = destination.caller_id_name or self.caller.caller_id_name;
        local from_uri = common.array.expand_variables(gateway.settings.from, destination, self.caller, { gateway = gateway });

        if gateway.settings.asserted_identity then
          local identity = common.array.expand_variables(gateway.settings.asserted_identity, destination, self.caller, { gateway = gateway })
          
          if self.caller.clir then
            caller_id_number = self.caller.anonymous_number or 'anonymous';
            caller_id_name = self.caller.anonymous_name or 'Anonymous';
            from_uri = common.array.expand_variables(gateway.settings.from_clir, destination, self.caller, { gateway = gateway }) or from_uri;
            identity = common.array.expand_variables(gateway.settings.asserted_identity_clir, destination, self.caller, { gateway = gateway }) or identity;
            table.insert(origination_variables, "origination_caller_id_number='" .. caller_id_number .. "'");
            table.insert(origination_variables, "origination_caller_id_name='" .. caller_id_name .. "'");
            table.insert(origination_variables, "sip_h_Privacy='id'");
          else
            if destination.caller_id_number then
              table.insert(origination_variables, "origination_caller_id_number='" .. destination.caller_id_number .. "'");
            end
            if destination.caller_id_name then
              table.insert(origination_variables, "origination_caller_id_name='" .. destination.caller_id_name .. "'");
            end
          end

          if from_uri then
            table.insert(origination_variables, "sip_from_uri='" .. from_uri .. "'");
          end

          if identity then
            table.insert(origination_variables, "sip_h_P-Asserted-Identity='" .. identity .. "'");
          end

          self.log:info('FORK ', index, '/', #destinations, ' - from: ', from_uri, ', identity: ', identity, ', privacy: ', self.caller.clir);
        else
          if destination.caller_id_number then
            table.insert(origination_variables, "origination_caller_id_number='" .. destination.caller_id_number .. "'");
          end
          if destination.caller_id_name then
            table.insert(origination_variables, "origination_caller_id_name='" .. destination.caller_id_name .. "'");
          end
        end

        if destination.channel_variables then
          for key, value in pairs(destination.channel_variables) do
            table.insert(origination_variables, tostring(key) .. "='" .. tostring(value) .. "'");
          end
        end

        table.insert(dial_strings, '[' .. table.concat(origination_variables , ',') .. ']' .. gateway:call_url(destination.number));
      else
        self.log:notice('FORK - gateway not found - gateway=', destination.id);
      end
    elseif destination.type == 'dial' then
      if destination.caller_id_number then
        table.insert(origination_variables, "origination_caller_id_number='" .. destination.caller_id_number .. "'");
      end
      if destination.caller_id_name then
        table.insert(origination_variables, "origination_caller_id_name='" .. destination.caller_id_name .. "'");
      end
      table.insert(dial_strings, '[' .. table.concat(origination_variables , ',') .. ']' .. destination.number);
    else
      self.log:info('FORK ', index, '/', #destinations, ' - unhandled destination type: ', destination.type, ', number: ', destination.number);
    end
  end

  if #dial_strings == 0 then
    self.log:notice('FORK - no active destinations - result: ', call_result.code, ' ', call_result.phrase);
    return call_result;
  end

  self.caller:set_callee_id(arg.callee_id_number, arg.callee_id_name);

  self.caller:set_variable('call_timeout', arg.timeout );
  self.log:info('FORK DIAL - destinations: ', #dial_strings, ', timeout: ', arg.timeout);

  for pickup_group, value in pairs(pickup_groups) do
    table.insert(dial_strings, 'pickup/' .. pickup_group);
  end

  if arg.send_ringing then
    self.caller:execute('ring_ready');
  end

  local session_dialstring = '{local_var_clobber=true}' .. table.concat(dial_strings, ',');
  self.log:debug('FORK SESSION_START - call_url: ', session_dialstring);
  local start_time = os.time();
  local session_callee = freeswitch.Session(session_dialstring, self.caller.session);
  self.log:debug('FORK SESSION_INIT - dial_time: ', os.time() - start_time);
  local answer_result = self:wait_answer(self.caller.session, session_callee, arg.timeout, start_time);
  local fork_index = nil;
  self.log:info('FORK ANSWER - status: ', answer_result, ', dial_time: ', os.time() - start_time);
  if answer_result == 'SUCCESS' then
    session_callee:setAutoHangup(false);
    fork_index = tonumber(session_callee:getVariable('gs_fork_index')) or 0;
    local destination = destinations[fork_index];

    if not destination then
      destination = {
        ['type'] = session_callee:getVariable('gs_account_type');
        id = session_callee:getVariable('gs_account_id');
        uuid = session_callee:getVariable('gs_account_uuid');
        pickup_group_pick = session_callee:getVariable('gs_pickup_group_pick');
      }
      self.log:notice('FORK - call picked off by: ', destination.type, '=', destination.id, '/', destination.uuid, ', pickup_group: ', destination.pickup_group_pick);
    end

    if arg.detect_dtmf_after_bridge_caller and self.caller.auth_account then
      if not string.match(self.caller:to_s('switch_r_sdp'), '101 telephone%-event') then
        self.log:notice('FORK A_LEG inband dtmf detection - channel_uuid: ', session:get_uuid());
        session:execute('start_dtmf');
      end
    end
    
    if arg.detect_dtmf_after_bridge_callee and destination.type == 'sipaccount' then
      if not string.match(tostring(session_callee:getVariable('switch_r_sdp')), '101 telephone%-event') then
        self.log:notice('FORK B_LEG inband dtmf detection - channel_uuid: ', session_callee:get_uuid());
        session_callee:execute('start_dtmf');
      end
    end

    if arg.bypass_media_network then
      local callee_uuid = session_callee:get_uuid();

      if callee_uuid and self.caller.uuid and freeswitch then
        require 'common.ipcalc'
        local callee_network_str = self.caller:to_s('bleg_network_addr');
        local caller_network_str = self.caller:to_s('network_addr');
        local callee_network_addr = common.ipcalc.ipv4_to_i(callee_network_str);
        local caller_network_addr = common.ipcalc.ipv4_to_i(caller_network_str);
        local network, netmask = common.ipcalc.ipv4_to_network_netmask(arg.bypass_media_network);
        if network and netmask and callee_network_addr and caller_network_addr
          and common.ipcalc.ipv4_in_network(callee_network_addr, network, netmask)
          and common.ipcalc.ipv4_in_network(caller_network_addr, network, netmask) then
          self.log:info('FORK ', fork_index, ' BYPASS_MEDIA - caller_ip: ', caller_network_str, 
            ', callee_ip: ', callee_network_str, 
            ', subnet: ', arg.bypass_media_network, 
            ', uuid: ', self.caller.uuid, ', bleg_uuid: ', callee_uuid);
          freeswitch.API():execute('uuid_media', 'off ' .. self.caller.uuid);
          freeswitch.API():execute('uuid_media', 'off ' .. callee_uuid);
        end
      end
    end

    if self.on_answer then
      self.on_answer(self.calling_object, destination);
    end

    self.caller:set_variable('gs_destination_type', destination.type);
    self.caller:set_variable('gs_destination_id', destination.id);
    self.caller:set_variable('gs_destination_uuid', destination.uuid);

    if arg.detect_dtmf_after_bridge_callee then
      session_callee:setInputCallback('input_call_back_callee', 'session_callee');
    end

    self.log:info('FORK ', fork_index, 
      ' BRIDGE - destination: ', destination.type, '=', destination.id, '/', destination.uuid,'@', destination.node_id, 
      ', number: ', destination.number,
      ', dial_time: ', os.time() - start_time);

    freeswitch.bridge(self.caller.session, session_callee);
    self:wait_hangup(self.caller.session, session_callee);
  end

  -- if session_callee:ready() then
    -- self.log:info('FORK - hangup destination channel');
    -- session_callee:hangup('ORIGINATOR_CANCEL');
  -- end

  call_result = {};
  call_result.disposition = session_callee:hangupCause();
  call_result.fork_index = fork_index;

  if some_destinations_busy and call_result.disposition == 'USER_NOT_REGISTERED' then
    call_result.phrase = 'User busy';
    call_result.code = 486;
    call_result.disposition = 'USER_BUSY';
  elseif call_result.disposition == 'USER_NOT_REGISTERED' then
    call_result.phrase = 'User offline';
    call_result.code = 480;
  elseif call_result.disposition == 'NO_ANSWER' then
    call_result.phrase = 'No answer';
    call_result.code = 408;
  elseif call_result.disposition == 'NORMAL_TEMPORARY_FAILURE' then
    call_result.phrase = 'User offline';
    call_result.code = 480;
  else
    call_result.cause = self.caller:to_s('last_bridge_hangup_cause');
    call_result.code = self.caller:to_i('last_bridge_proto_specific_hangup_cause');
    call_result.phrase = self.caller:to_s('sip_hangup_phrase');
  end

  self.log:info('FORK EXIT - disposition: ', call_result.disposition, 
    ', cause: ', call_result.cause,
    ', code: ', call_result.code, 
    ', phrase: ', call_result.phrase, 
    ', dial_time: ', os.time() - start_time);
  
  return call_result;
end

-- Return call forwarding settngs
function SipCall.conditional_call_forwarding(self, cause, call_forwarding)
  local condition_map = {USER_NOT_REGISTERED="offline", NO_ANSWER="noanswer", USER_BUSY="busy"}
  local condition = condition_map[cause]
  if call_forwarding and condition and call_forwarding[condition] then
    log:debug('call forwarding on ' .. condition .. ' - destination: ' .. call_forwarding[condition].destination .. ', type: ' .. call_forwarding[condition].call_forwardable_type);
    return call_forwarding[condition]
  end
end

function SipCall.set_callee_variables(self, sip_account)
  self.session:setVariable("gs_callee_account_id", sip_account.id);
  self.session:setVariable("gs_callee_account_type", "SipAccount");
  self.session:setVariable("gs_callee_account_owner_type", sip_account.sip_accountable_type);
  self.session:setVariable("gs_callee_account_owner_id", sip_account.sip_accountable_id);
end
