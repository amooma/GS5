-- Gemeinschaft 5 module: dialplan class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

Dialplan = {}

-- local constants
local DIAL_TIMEOUT = 120;
local MAX_LOOPS = 20;
local DIALPLAN_FUNCTION_PATTERN = '^f[_%-].*';
local CALL_FORWARDING_SERVICES = {
  USER_BUSY = 'busy',
  CALL_REJECTED = 'busy',
  NO_ANSWER = 'noanswer',
  USER_NOT_REGISTERED = 'offline',
  HUNT_GROUP_EMPTY = 'offline',
  ACD_NO_AGENTS = 'offline',
  ACD_TIMEOUT = 'noanswer',
  NO_USER_RESPONSE = 'offline',
}

-- create dialplan object
function Dialplan.new(self, arg)
  require 'common.str';
  require 'common.array';

  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.database = arg.database;
  self.caller = arg.caller;

  return object;
end


function Dialplan.domain_get(self, domain)
  local global_domain = freeswitch.API():execute('global_getvar', 'domain');

  if common.str.blank(global_domain) then
    if common.str.blank(domain) then
      require 'common.database'
      local database = common.database.Database:new{ log = self.log }:connect();
      if not database:connected() then
        self.log:error('[', uuid,'] DIALPLAN_DOMAIN - cannot connect to Gemeinschaft database');
      else
        require 'configuration.sip'
        local domains = configuration.sip.Sip:new{ log = self.log, database = database }:domains();
        if domains[1] then
          domain = domains[1]['host'];
        end
      end
    end

    if database then
      database:release();
    end

    if not common.str.blank(domain) then
      self.log:notice('DIALPLAN_DOMAIN - setting default domain: ', domain);
      freeswitch.API():execute('global_setvar', 'domain=' .. tostring(domain));
    end
  else
    domain = global_domain;
  end

  if common.str.blank(domain) then
    self.log:error('DIALPLAN_DOMAIN - no domain found');
  end

  return domain;
end


function Dialplan.configuration_read(self)
  require 'common.configuration_table';

  -- dialplan configuration
  self.config  = common.configuration_table.get(self.database, 'dialplan');
  self.node_id = common.str.to_i(self.config.parameters.node_id);
  self.domain =  self:domain_get(self.config.parameters.domain);
  self.dial_timeout = tonumber(self.config.parameters.dial_timeout) or DIAL_TIMEOUT;
  self.max_loops = tonumber(self.config.parameters.max_loops) or MAX_LOOPS;
  self.user_image_url = common.str.to_s(self.config.parameters.user_image_url);
  self.phone_book_entry_image_url = common.str.to_s(self.config.parameters.phone_book_entry_image_url);
  self.phonebook_number_lookup = self.config.parameters.phonebook_number_lookup;
  self.geo_number_lookup = self.config.parameters.geo_number_lookup;
  self.default_language = self.config.parameters.default_language or 'en';
  self.send_ringing_to_gateways = self.config.parameters.send_ringing_to_gateways;
  
  if tonumber(self.config.parameters.default_ringtone) then
    self.default_ringtone = 'http://amooma.de;info=Ringer' .. self.config.parameters.default_ringtone .. ';x-line-id=0';
  else
    self.default_ringtone = 'http://amooma.de;info=Ringer1;x-line-id=0';
  end

  return (self.config ~= nil);
end


function Dialplan.hangup(self, code, phrase, cause)
  if self.caller:ready() then
    if tonumber(code) then
      self.caller:respond(code, phrase or 'Thank you for flying Gemeinschaft5');
    end
    self.caller:hangup(cause or 16);
  else
    self.log:info('HANGUP - caller sesson down - cause: ', self.caller.session:hangupCause());
  end
end


function Dialplan.auth_node(self)
  require 'common.node'
  local node = common.node.Node:new{ log = self.log, database = self.database }:find_by_address(self.caller.sip_contact_host);

  if node then
    self.log:info('AUTH_NODE - node_id: ', self.caller.node_id, ', contact address:', self.caller.sip_contact_host);
    return true;
  end
end


function Dialplan.auth_account(self)
  if not common.str.blank(self.caller.auth_account_type) then
    self.log:info('AUTH auth_account - ', self.caller.auth_account_type, '=', self.caller.account_id, '/', self.caller.account_uuid);
    return true;
  elseif not common.str.blank(self.caller.previous_destination_type) and not common.str.blank(self.caller.previous_destination_uuid) then
    self.log:info('AUTH previous_destination - ', self.caller.previous_destination_type, '=', self.caller.previous_destination_id, '/', self.caller.previous_destination_uuid);
    return true;
  end
end


function Dialplan.auth_gateway(self)
  require 'common.gateway';
  local gateway_class = common.gateway.Gateway:new{ log = self.log, database = self.database};

  local gateway = false;

  if self.caller:to_b('gs_from_gateway') then
    gateway = {
      name = self.caller:to_s('gs_gateway_name'),
      id = self.caller:to_i('gs_gateway_id'),
    }
    log:info('AUTH gateway - authenticaded by password and username: ', self.caller:to_s('username'), ', gateway=', gateway.id, '|', gateway.name, ', ip: ', self.caller.sip_contact_host);
    return gateway_class:find_by_id(gateway.id);
  else
    gateway = gateway_class:authenticate(self.caller);
  end

  if gateway then
    log:info('AUTH gateway - ', gateway.auth_source, ' ~ ', gateway.auth_pattern, ', gateway=', gateway.id, '|', gateway.name, ', ip: ', self.caller.sip_contact_host);
    return gateway_class:find_by_id(gateway.id);
  end
end


function Dialplan.object_find(self, arguments)
  require 'common.object';
  return common.object.Object:new{ log = self.log, database = self.database}:find(arguments);
end


function Dialplan.retrieve_caller_data(self)
  self.caller.caller_phone_numbers_hash = {};

  if not common.str.blank(self.caller.previous_destination_type) and not common.str.blank(self.caller.previous_destination_uuid) then
    self.log:debug('CALLER_DATA - authenticate by previous destination: ', self.caller.previous_destination_type, '=', self.caller.previous_destination_id, '/', self.caller.previous_destination_uuid);
    self.caller.auth_account = self:object_find{class = self.caller.previous_destination_type, uuid = self.caller.previous_destination_uuid};
  elseif not common.str.blank(self.caller.auth_account_type) and not common.str.blank(self.caller.auth_account_uuid) then
    self.caller.auth_account = self:object_find{class = self.caller.auth_account_type, uuid = self.caller.auth_account_uuid};
  elseif not common.str.blank(self.caller.dialed_sip_user) then
    self.caller.auth_account = self:object_find{class = 'sipaccount', domain = self.caller.dialed_domain, auth_account = self.caller.dialed_sip_user};
  end

  if self.caller.auth_account then
    self.log:info('CALLER_DATA - auth account: ', self.caller.auth_account.class, '=', self.caller.auth_account.id, '/', self.caller.auth_account.uuid, ', groups: ', table.concat(self.caller.auth_account.groups, ','));
    if self.caller.auth_account.owner then
      self.log:info('CALLER_DATA - auth owner: ', self.caller.auth_account.owner.class, '=', self.caller.auth_account.owner.id, '/', self.caller.auth_account.owner.uuid, ', groups: ', table.concat(self.caller.auth_account.owner.groups, ','));
    else
      self.log:error('CALLER_DATA - auth owner not found');
    end
    if self.caller.set_auth_account then
      self.caller:set_auth_account(self.caller.auth_account);
    end
  else
    self.log:info('CALLER_DATA - no data - unauthenticated call: ', self.caller.auth_account_type, '=', self.caller.auth_account_id, '/', self.caller.auth_account_uuid);
  end

  if not common.str.blank(self.caller.account_type) and not common.str.blank(self.caller.account_uuid) then
    self.caller.account = self:object_find{class = self.caller.account_type, uuid = self.caller.account_uuid};
    if self.caller.account then
      self.caller.clir = common.str.to_b(common.array.try(self.caller, 'account.record.clir'));
      self.caller.clip = common.str.to_b(common.array.try(self.caller, 'account.record.clip'));

      require 'common.phone_number'
      self.caller.caller_phone_numbers = common.phone_number.PhoneNumber:new{ log = self.log, database = self.database }:list_by_owner(self.caller.account.id, self.caller.account.class);
      for index, caller_number in ipairs(self.caller.caller_phone_numbers) do
        self.caller.caller_phone_numbers_hash[caller_number] = true;
      end
      if not common.str.blank(self.caller.account.record.language_code) then
        self.caller.language = self.caller.account.record.language_code;
      end
      self.log:info('CALLER_DATA - caller account: ', self.caller.account.class, '=', self.caller.account.id, '/', self.caller.account.uuid, ', phone_numbers: ', #self.caller.caller_phone_numbers, ', language: ', self.caller.language, ', groups: ', table.concat(self.caller.account.groups, ','));
      if self.caller.account.owner then
        self.log:info('CALLER_DATA - caller owner: ', self.caller.account.owner.class, '=', self.caller.account.owner.id, '/', self.caller.account.owner.uuid, ', groups: ', table.concat(self.caller.account.owner.groups, ','));
      else
        self.log:error('CALLER_DATA - caller owner not found');
      end

      if not self.caller.clir and self.caller.set_caller_id then
        self.caller:set_caller_id(self.caller.caller_phone_numbers[1], self.caller.account.record.caller_name or self.caller.account.record.name);
      end
    else
      self.log:error('CALLER_DATA - caller account not found: ', self.caller.account_type, '/', self.caller.account_uuid);
    end
  end
end


function Dialplan.destination_new(self, arg)
  local destination = {
    number = arg.number or '',
    type = arg.type or 'unknown',
    id = common.str.to_i(arg.id),
    uuid = arg.uuid or '',
    phone_number = arg.phone_number,
    node_id = common.str.to_i(arg.node_id),
    call_forwarding = {},
    data = arg.data,
  }

  destination.type = common.str.downcase(destination.type);

  if not common.str.blank(destination.number) then
    if destination.type == 'unknown' and destination.number:find(DIALPLAN_FUNCTION_PATTERN) then
      destination.type = 'dialplanfunction';
    elseif destination.type == 'phonenumber' or destination.type == 'unknown' then
      require 'common.phone_number'
      destination.phone_number = common.phone_number.PhoneNumber:new{ log = self.log, database = self.database }:find_by_number(destination.number);
      
      if destination.phone_number then
        destination.type    = common.str.downcase(destination.phone_number.record.phone_numberable_type);
        destination.id      = common.str.to_i(destination.phone_number.record.phone_numberable_id);
        destination.uuid    = common.str.to_s(destination.phone_number.record.phone_numberable_uuid);
        destination.node_id = common.str.to_i(destination.phone_number.record.gs_node_id);
        destination.account = self:object_find{ class = destination.type, id = destination.id};
        if self.caller then
          require 'common.call_forwarding';
          local call_forwarding_class = common.call_forwarding.CallForwarding:new{ log = self.log, database = self.database, caller = self.caller }
          destination.call_forwarding = call_forwarding_class:list_by_owner(destination.id, destination.type, self.caller.caller_phone_numbers);
          for service, call_forwarding_entry in pairs(call_forwarding_class:list_by_owner(destination.phone_number.id, destination.phone_number.class, self.caller.caller_phone_numbers)) do
            destination.call_forwarding[service] = call_forwarding_entry;
          end
          -- destination.call_forwarding = destination.phone_number:call_forwarding(self.caller.caller_phone_numbers);
        end
      elseif destination.type == 'unknown' then
        require 'common.sip_account'
        destination.account = common.sip_account.SipAccount:new{ log = self.log, database = self.database }:find_by_auth_name(destination.number);
        if destination.account then
          destination.type    = 'sipaccount';
          destination.id      = common.str.to_i(destination.account.record.id);
          destination.uuid    = common.str.to_s(destination.account.record.uuid);
          destination.node_id = common.str.to_i(destination.account.record.gs_node_id);
        end
      end
    end
  end

  if destination.node_id == 0 then
    destination.node_id = self.node_id;
    destination.node_local = true;
  else
    destination.node_local = (destination.node_id == self.node_id);
  end

  self.log:info('DESTINATION_NEW - ', destination.type, '=', destination.id, '/', destination.uuid,'@', destination.node_id, ', number: ', destination.number);

  return destination;
end


function Dialplan.set_caller_picture(self, entry_id, entry_type, image)
  entry_type = entry_type:lower();
  if entry_type == 'user' then
    require 'dialplan.user'
    local user = dialplan.user.User:new{ log = self.log, database = self.database }:find_by_id(entry_id);
    if user then
      self.caller:export_variable('sip_h_Call-Info', '<' .. self.user_image_url .. '/' .. tonumber(entry_id) .. '/snom_caller_picture_' .. tostring(user.record.image) .. '>;purpose=icon');
    end 
  elseif entry_type == 'phonebookentry' and image then
    self.caller:export_variable('sip_h_Call-Info', '<' .. self.phone_book_entry_image_url .. '/' .. tonumber(entry_id) .. '/snom_caller_picture_' .. tostring(image) .. '>;purpose=icon');
  end
end


function Dialplan.dial(self, destination)
  local user_id = nil; 
  local tenant_id = nil;

  destination.caller_id_number = destination.caller_id_number or self.caller.caller_phone_numbers[1];

  if destination.node_local and destination.type == 'sipaccount' then
    destination.pickup_groups = {};

    destination.account = self:object_find{class = destination.type, id = destination.id};
    if destination.account then
      destination.uuid = destination.account.uuid;
      if destination.account.class == 'sipaccount' then
        destination.callee_id_name = destination.account.record.caller_name;
        self.caller:set_callee_id(destination.number, destination.account.record.caller_name);
        table.insert(destination.pickup_groups, 's' .. destination.account.id );
      end
      require 'common.group';
      local group_names, group_ids = common.group.Group:new{ log = self.log, database = self.database }:name_id_by_permission(destination.id, destination.type, 'pickup');
      self.log:debug('DESTINATION_GROUPS - pickup_groups: ', table.concat(group_names, ','));
      for index=1, #group_ids do
        table.insert(destination.pickup_groups, 'g' .. group_ids[index]);
      end 
    end

    if destination.account and destination.account.owner then
      if destination.account.owner.class == 'user' then
        user_id = destination.account.owner.id;
        tenant_id = tonumber(destination.account.owner.record.current_tenant_id);
        local user = self:object_find{class = destination.account.owner.class, id = tonumber(user_id)};
      elseif destination.account.owner.class == 'tenant' then
        tenant_id = destination.account.owner.id;
      end
      self.caller:set_variable('gs_destination_owner_type', destination.account.owner.class);
      self.caller:set_variable('gs_destination_owner_id', destination.account.owner.id);
      self.caller:set_variable('gs_destination_owner_uuid', destination.account.owner.uuid);
    end
  end

  if not self.caller.clir then
    if user_id or tenant_id then

      if self.phonebook_number_lookup then
        require 'dialplan.phone_book'
        self.caller.phone_book_entry = dialplan.phone_book.PhoneBook:new{ log = self.log, database = self.database }:find_entry_by_number_user_tenant(self.caller.caller_phone_numbers, user_id, tenant_id);
      end

      if self.caller.phone_book_entry then
        self.log:info('PHONE_BOOK_ENTRY - phone_book=', self.caller.phone_book_entry.phone_book_id, ' (', self.caller.phone_book_entry.phone_book_name, '), caller_id_name: ', self.caller.phone_book_entry.caller_id_name, ', ringtone: ', self.caller.phone_book_entry.bellcore_id);
        destination.caller_id_name = common.str.to_ascii(self.caller.phone_book_entry.caller_id_name);
        if tonumber(self.caller.phone_book_entry.bellcore_id) then
          self.log:debug('RINGTONE - phonebookentry=', self.caller.phone_book_entry.id, ', ringtone: ', self.caller.phone_book_entry.bellcore_id);
          self.caller:export_variable('alert_info', 'http://amooma.de;info=Ringer' .. self.caller.phone_book_entry.bellcore_id .. ';x-line-id=0');
        end
        if not common.str.blank(self.caller.phone_book_entry.image) then
          self:set_caller_picture(self.caller.phone_book_entry.id, 'phonebookentry', self.caller.phone_book_entry.image);
        elseif self.caller.account and self.caller.account.owner then
          self:set_caller_picture(self.caller.account.owner.id, self.caller.account.owner.class);
        end
      elseif self.caller.account and self.caller.account.owner then
        self:set_caller_picture(self.caller.account.owner.id, self.caller.account.owner.class);
      elseif self.geo_number_lookup then
        require 'dialplan.geo_number'
        local geo_number = dialplan.geo_number.GeoNumber:new{ log = self.log, database = self.database }:find(destination.caller_id_number);
        if geo_number then
          self.log:info('GEO_NUMBER - found: ', geo_number.name, ', ', geo_number.country);
          if geo_number.name then
            destination.caller_id_name = common.str.to_ascii(geo_number.name) .. ', ' .. common.str.to_ascii(geo_number.country);
          else
            destination.caller_id_name = common.str.to_ascii(geo_number.country);
          end
        end
      end
    end
    self.caller:set_caller_id(destination.caller_id_number, destination.caller_id_name or self.caller.caller_id_name);
  end

  local destinations = { destination };

  if self.caller.forwarding_service == 'assistant' and self.caller.auth_account and self.caller.auth_account.class == 'sipaccount' then
    self.caller.auth_account.type = self.caller.auth_account.class;
    local forwarding_destination = self:destination_new( self.caller.auth_account );
    if forwarding_destination then
      forwarding_destination.alert_info = 'http://amooma.com;info=Ringer0;x-line-id=0'
      table.insert(destinations, forwarding_destination);
    end
  end

  require 'dialplan.sip_call'
  return dialplan.sip_call.SipCall:new{ log = self.log, database = self.database, caller = self.caller }:fork(
    destinations,
    { timeout =  self.dial_timeout_active, 
      send_ringing = ( self.send_ringing_to_gateways and self.caller.from_gateway ),
      bypass_media_network = self.config.parameters.bypass_media_network,
      update_callee_display = self.config.parameters.update_callee_display,
      detect_dtmf_after_bridge_caller = self.detect_dtmf_after_bridge_caller,
      detect_dtmf_after_bridge_callee = self.detect_dtmf_after_bridge_callee,
    }
  );
end


function Dialplan.huntgroup(self, destination)
  local hunt_group = self:object_find{class = 'huntgroup', id = tonumber(destination.id)};

  if not hunt_group then
    self.log:error('DIALPLAN_HUNTGROUP - huntgroup not found');
    return { continue = true, code = 404, phrase = 'Huntgroup not found' }
  end

  self.caller:set_callee_id(destination.number, hunt_group.record.name);
  destination.caller_id_number = destination.caller_id_number or self.caller.caller_phone_numbers[1];

  if not self.caller.clir then
    self.caller:set_caller_id(destination.caller_id_number, tostring(hunt_group.record.name) .. ' '.. tostring(self.caller.caller_id_name));
    if self.caller.account and self.caller.account.owner then
      self:set_caller_picture(self.caller.account.owner.id, self.caller.account.owner.class);
    end
  else
    self.caller.anonymous_name = tostring(hunt_group.record.name);
  end
  
  self.caller.auth_account = hunt_group;
  self.caller:set_auth_account(self.caller.auth_account);
  self.caller.forwarding_number = destination.number;
  self.caller.forwarding_service = 'huntgroup';
  self.caller:set_variable('gs_forwarding_service', self.caller.forwarding_service);
  self.caller:set_variable('gs_forwarding_number', self.caller.forwarding_number);
  return hunt_group:run(self, self.caller, destination);
end


function Dialplan.acd(self, destination)
  local acd = self:object_find{class = 'automaticcalldistributor', id = tonumber(destination.id)};
  
  if not acd then
    self.log:error('DIALPLAN_ACD - acd not found');
    return { continue = true, code = 404, phrase = 'ACD not found' }
  end

  self.caller:set_callee_id(destination.number, acd.record.name);
  destination.caller_id_number = destination.caller_id_number or self.caller.caller_phone_numbers[1];

  if not self.caller.clir then
    self.caller:set_caller_id(destination.caller_id_number, tostring(acd.record.name) .. ' '.. tostring(self.caller.caller_id_name));
    if self.caller.account and self.caller.account.owner then
      self:set_caller_picture(self.caller.account.owner.id, self.caller.account.owner.class);
    end
  else
    self.caller.anonymous_name = tostring(acd.record.name);
  end

  self.caller.auth_account = acd;
  self.caller:set_auth_account(self.caller.auth_account);
  self.caller.forwarding_number = destination.number;
  self.caller.forwarding_service = 'automaticcalldistributor';
  self.caller:set_variable('gs_forwarding_service', self.caller.forwarding_service);
  self.caller:set_variable('gs_forwarding_number', self.caller.forwarding_number);

  acd:caller_new(self.caller.uuid);
  local result = acd:run(self, self.caller, destination);
  acd:caller_delete();

  return result;
end


function Dialplan.conference(self, destination)
  require 'common.conference';
  local conference = common.conference.Conference:new{ log = self.log, database = self.database }:find_by_id(destination.id);
 
  if not conference then
    return { continue = false, code = 404, phrase = 'Conference not found' }
  end

  return conference:enter(self.caller, self.domain);
end


function Dialplan.faxaccount(self, destination)
  require 'dialplan.fax'
  local fax_account = dialplan.fax.Fax:new{ log = self.log, database = self.database }:find_by_id(destination.id);

  if not fax_account then
    return { continue = false, code = 404, phrase = 'Fax not found' }
  end

  self.log:info('FAX_RECEIVE start - fax_account=', fax_account.id, '/', fax_account.uuid, ', name: ', fax_account.record.name, ', station_id: ', fax_account.record.station_id);

  self.caller:set_caller_id(self.caller.caller_phone_number);
  self.caller:set_callee_id(destination.number, fax_account.record.name);

  local fax_document = fax_account:receive(self.caller);

  if not fax_document then
    self.log:error('FAX_RECEIVE - error receiving fax document - fax_account=', fax_account.id, '/', fax_account.uuid);
    return { continue = false, code = 500, phrase = 'Error receiving fax' };
  end

  fax_document.caller_id_number = self.caller.caller_phone_number;
  fax_document.caller_id_name = self.caller.caller_id_name;
  fax_document.uuid = self.caller.uuid;

  self.log:info('FAX_RECEIVE end - success: ', fax_document.success, 
    ', remote: ', fax_document.remote_station_id, 
    ', pages: ', fax_document.transferred_pages, '/', fax_document.total_pages,
    ', result: ', fax_document.result_code, ' ', fax_document.result_text);

  if fax_document.success then
    self.log:notice('FAX_RECEIVE - saving fax document: ', fax_document.filename );
    if not fax_account:insert_document(fax_document) then
      self.log:error('FAX_RECEIVE - error inserting fax document to database - fax_account=', fax_account.id, '/', fax_account.uuid, ', file: ', fax_document.filename);
    end
    fax_account:trigger_notification(fax_account.id, self.caller.uuid);
  end
  
  return { continue = false, code = 200, phrase = 'OK' }
end


function Dialplan.callthrough(self, destination)
  -- Callthrough
  require 'dialplan.callthrough'
  callthrough = dialplan.callthrough.Callthrough:new{ log = self.log, database = self.database }:find_by_id(destination.id)
  
  if not callthrough then
    self.log:error('CALLTHROUGH - no callthrough for destination number: ',  destination.number);
    return { continue = false, code = 404, phrase = 'Fax not found' }
  end
  self.log:info('CALLTHROUGH - number: ' .. destination.number .. ', name: ' .. callthrough.record.name);

  local authorization = callthrough:authenticate(self.caller);

  if not authorization then
    self.log:notice('CALLTHROUGH - authentication failed');
    return { continue = false, code = 403, phrase = 'Authentication failed' }
  end

  if type(authorization) == 'table' and tonumber(authorization.sip_account_id) and tonumber(authorization.sip_account_id) > 0 then
    local auth_account                  = self:object_find{class = 'sipaccount', id = tonumber(authorization.sip_account_id)};
    self.caller.forwarding_number       = destination.number;
    self.caller.forwarding_service      = 'callthrough';
    self.caller:set_variable('gs_forwarding_service', self.caller.forwarding_service);
    self.caller:set_variable('gs_forwarding_number', self.caller.forwarding_number);

    if auth_account then
      self.caller.auth_account = auth_account;
      self.caller:set_auth_account(self.caller.auth_account);
      self.log:info('AUTH_ACCOUNT_UPDATE - account: ', self.caller.auth_account.class, '=', self.caller.auth_account.id, '/', self.caller.auth_account.uuid);      
      if self.caller.auth_account.owner then
        self.log:info('AUTH_ACCOUNT_UPDATE - auth owner: ', self.caller.auth_account.owner.class, '=', self.caller.auth_account.owner.id, '/', self.caller.auth_account.owner.uuid);
      else
        self.log:error('AUTH_ACCOUNT_UPDATE - auth owner not found');
      end
      self.log:info('CALLTHROUGH - use sip account: ', auth_account.id, ' (', auth_account.record.caller_name, ')');
    end
  else
    self.log:info('CALLTHROUGH - no sip account');
  end

  local destination_number = '';
  for i = 1, 3, 1 do
    if destination_number ~= '' then
      break;
    end
    destination_number = session:read(2, 16, "ivr/ivr-enter_destination_telephone_number.wav", 3000, "#");
  end

  if destination_number == '' then
    self.log:debug("no callthrough destination - hangup call");
    return { continue = false, code = 404, phrase = 'No destination' }
  end

  require 'dialplan.router'
  local route =  dialplan.router.Router:new{ log = self.log, database = self.database, caller = self.caller, variables = self.caller }:route_run('prerouting', true);

  if route and route.destination_number then
    destination_number = route.destination_number;
  end

  if not callthrough:whitelist(destination_number) then
    self.log:debug('caller not authorized to call destination number: ' .. destination_number .. ' - hangup call');
    return { continue = false, code = 403, phrase = 'Unauthorized' }
  end

  return { continue = true, code = 302, number = destination_number }
end


function Dialplan.voicemail(self, destination)
  require 'dialplan.voicemail';

  local voicemail_account = nil;
  if common.str.to_i(destination.id) > 0 then
    voicemail_account = dialplan.voicemail.Voicemail:new{ log = self.log, database = self.database, domain = self.domain }:find_by_id(destination.id);
  elseif self.caller.auth_account and self.caller.auth_account.class == 'sipaccount' then
    voicemail_account = dialplan.voicemail.Voicemail:new{ log = self.log, database = self.database, domain = self.domain }:find_by_sip_account_id(self.caller.auth_account.id);
  elseif self.caller.forwarding_number then
    voicemail_account = dialplan.voicemail.Voicemail:new{ log = self.log, database = self.database, domain = self.domain }:find_by_number(self.caller.forwarding_number);
  end

  if not voicemail_account then
    self.log:error('VOICEMAIL - mailbox not found, ');
    return { continue = false, code = 404, phrase = 'Mailbox not found' }
  end

  voicemail_account:leave(self.caller, destination.number, self.caller.forwarding_number);

  if self.caller:to_s("voicemail_message_len") == '' then
    self.log:info('VOICEMAIL - no message saved');
  end
  
  return { continue = false, code = 200 }
end


function Dialplan.dialplanfunction(self, destination)
  require 'dialplan.functions'
  return dialplan.functions.Functions:new{ log = self.log, database = self.database, domain = self.domain, parent = self }:dialplan_function(self.caller, destination.number);
end


function Dialplan.switch(self, destination)
  local result = nil;
  self.dial_timeout_active = self.dial_timeout;

  if not destination.node_local then
    return self:dial(destination);
  end
  
  for service, call_forwarding in pairs(destination.call_forwarding) do
    if self.caller.caller_phone_numbers_hash[call_forwarding.number] then
      self.log:info('CALL_FORWARDING - caller number equals destination: ', call_forwarding.number,' - ignore service: ', service);
      destination.call_forwarding[service] = nil;
    end
  end

  if destination.call_forwarding.noanswer then
    self.dial_timeout_active = tonumber(destination.call_forwarding.noanswer.timeout) or self.dial_timeout;
  end

  if destination.call_forwarding.always then
    return { continue = true, call_forwarding = destination.call_forwarding.always }
  elseif destination.call_forwarding.assistant then
    if common.str.downcase(destination.call_forwarding.assistant.type) == 'huntgroup' then
      require 'dialplan.hunt_group'
      local hunt_group = dialplan.hunt_group.HuntGroup:new{ log = self.log, database = self.database }:find_by_id(destination.call_forwarding.assistant.id);
      self.log:info('CALL_FORWARDING - huntgroup - auth_account: ', self.caller.auth_account_type, '=', self.caller.auth_account_uuid);
      if hunt_group and (hunt_group:is_member_by_numbers(self.caller.caller_phone_numbers)) then
        self.log:info('CALL_FORWARDING - caller is huntgroup member - ignore service: ', destination.call_forwarding.assistant.service);
      else
        return { continue = true, call_forwarding = destination.call_forwarding.assistant }
      end
    else
      return { continue = true, call_forwarding = destination.call_forwarding.assistant }
    end
  end

  -- reset ringtone
  self.caller:export_variable('alert_info', self.default_ringtone);

  if destination.phone_number then
    destination.ringtone = destination.phone_number:ringtone();
  end

  if not destination.ringtone and destination.account and destination.account.ringtone then
    destination.ringtone = destination.account:ringtone();
  end

  if destination.ringtone then
    if destination.ringtone.bellcore_id then
      self.log:debug('DESTINATION_RINGTONE - ', destination.ringtone.ringtoneable_type .. '=', destination.ringtone.ringtoneable_id, ', ringtone: ' .. destination.ringtone.bellcore_id);
      self.caller:export_variable('alert_info', 'http://amooma.de;info=Ringer' .. tonumber(destination.ringtone.bellcore_id) .. ';x-line-id=0');
    end
  end

  if destination.type == 'sipaccount' then
    result = self:dial(destination);
    if CALL_FORWARDING_SERVICES[result.disposition] then
      result.call_forwarding = destination.call_forwarding[CALL_FORWARDING_SERVICES[result.disposition]];
      if result.call_forwarding then
        result.continue = true;
      end
    end
    return result;
  elseif destination.type == 'conference' then
    return self:conference(destination);
  elseif destination.type == 'faxaccount' then
    return self:faxaccount(destination);
  elseif destination.type == 'callthrough' then
    return self:callthrough(destination);
  elseif destination.type == 'huntgroup' then
    result = self:huntgroup(destination);
    if CALL_FORWARDING_SERVICES[result.disposition] then
      result.call_forwarding = destination.call_forwarding[CALL_FORWARDING_SERVICES[result.disposition]];
      if result.call_forwarding then
        result.continue = true;
      end
    end
    return result;
  elseif destination.type == 'automaticcalldistributor' then
    result = self:acd(destination);
    if CALL_FORWARDING_SERVICES[result.disposition] then
      result.call_forwarding = destination.call_forwarding[CALL_FORWARDING_SERVICES[result.disposition]];
      if result.call_forwarding then
        result.continue = true;
      end
    end
    return result;
  elseif destination.type == 'voicemail' or destination.type == 'voicemailaccount' then
    return self:voicemail(destination);
  elseif destination.type == 'dialplanfunction' then
    return self:dialplanfunction(destination);
  elseif not common.str.blank(destination.number) then
    local result = { continue = false, code = 404, phrase = 'No route' }

    local clip_no_screening = common.array.try(self.caller, 'account.record.clip_no_screening');
    self.caller.caller_id_numbers = {}
    if not common.str.blank(clip_no_screening) then
      for index, number in ipairs(common.str.strip_to_a(clip_no_screening, ',')) do
        table.insert(self.caller.caller_id_numbers, number);
      end
    end
    for index, number in ipairs(self.caller.caller_phone_numbers) do
      table.insert(self.caller.caller_id_numbers, number);
    end

    self.log:info('SWITCH - clir: ', self.caller.clir, ', caller_id_numbers: ', table.concat(self.caller.caller_id_numbers, ','));
    destination.callee_id_number = destination.number;
    destination.callee_id_name = nil;

    if self.phonebook_number_lookup then
      local user_id = common.array.try(self.caller, 'account.owner.id');
      local tenant_id = common.array.try(self.caller, 'account.owner.record.current_tenant_id');

      if user_id or tenant_id then
        require 'dialplan.phone_book'
        self.caller.callee_phone_book_entry = dialplan.phone_book.PhoneBook:new{ log = self.log, database = self.database }:find_entry_by_number_user_tenant({ destination.number }, user_id, tenant_id);
        if self.caller.callee_phone_book_entry then
          self.log:info('PHONE_BOOK_ENTRY - phone_book=', self.caller.callee_phone_book_entry.phone_book_id, ' (', self.caller.callee_phone_book_entry.phone_book_name, '), callee_id_name: ', common.str.to_ascii(self.caller.callee_phone_book_entry.caller_id_name));
          destination.callee_id_name = common.str.to_ascii(self.caller.callee_phone_book_entry.caller_id_name);
        end
      end 
    end

    if self.geo_number_lookup and not destination.callee_id_name then
      require 'dialplan.geo_number'
      local geo_number = dialplan.geo_number.GeoNumber:new{ log = self.log, database = self.database }:find(destination.number);
      if geo_number then
        self.log:info('GEO_NUMBER - found: ', geo_number.name, ', ', geo_number.country);
        if geo_number.name then
          destination.callee_id_name = common.str.to_ascii(geo_number.name) .. ', ' .. common.str.to_ascii(geo_number.country);
        else
          destination.callee_id_name = common.str.to_ascii(geo_number.country);
        end
      end
    end

    self.caller:set_callee_id(destination.callee_id_number, destination.callee_id_name);

    require 'dialplan.router'
    local routes =  dialplan.router.Router:new{ log = self.log, database = self.database, caller = self.caller, variables = self.caller }:route_run('outbound');
    
    if not routes or #routes == 0 then
      self.log:notice('SWITCH - no route - number: ', destination.number);
      return { continue = false, code = 404, phrase = 'No route' }
    end
    
    for index, route in ipairs(routes) do
      self.caller:set_callee_id(route.callee_id_number or destination.callee_id_number, route.callee_id_name or destination.callee_id_name);
      if route.type == 'hangup' then
        self.log:notice('SWITCH_HANGUP - code: ', route.code, ', phrase: ', route.phrase, ', cause: ', route.cause);
        return { continue = false, code = route.code or '404', phrase = route.phrase, cause = route.cause }
      end
      if route.type == 'forward' then
        self.log:notice('SWITCH_CALL_FORWARDING - number: ', route.number);
        return { continue = true, call_forwarding = { number = route.number, service = 'route', type = 'phonenumber' }}
      end

      for key, value in pairs(route) do
        destination[key] = value;
      end

      result = self:dial(destination);

      if result.continue == false then
        break;
      end

      if common.str.to_b(self.route_failover[tostring(result.code)]) == true then
        self.log:info('SWITCH - failover - code: ', result.code);
      elseif common.str.to_b(self.route_failover[tostring(result.cause)]) == true then
        self.log:info('SWITCH - failover - cause: ', result.cause);
      else
        self.log:info('SWITCH - no failover - cause: ', result.cause, ', code: ', result.code);
        break;
      end
    end

    return result;
  end

  self.log:error('SWITCH - destination not found - type: ', destination.type);
  return { continue = true, code = 404, phrase = destination.type .. ' not found' }
end


function Dialplan.run(self, destination)
  require 'dialplan.router';
  
  self.caller:set_variable('hangup_after_bridge', false);
  self.caller:set_variable('bridge_early_media', 'true');
  self.caller:set_variable('gs_save_cdr', true);
  self.caller:set_variable('gs_call_service', 'dial');
  self.caller.session:setAutoHangup(false);
  self.caller.date = os.date('%y%m%d%w');
  self.caller.time = os.date('%H%M%S');

  if self.config then
    self.caller:export_variable('sip_cid_type=' .. (self.config.sip_cid_type or 'none'));
  end
  
  if type(self.config.variables) == 'table' then
    for key, value in pairs(self.config.variables) do
      self.caller:set_variable(key, value);
    end
  end

  self.caller.domain_local = self.domain;
  self:retrieve_caller_data();
  self.route_failover = common.configuration_table.get(self.database, 'call_route', 'failover');

  self.caller.language = self.caller.language or self.default_language;

  if not destination or destination.type == 'unknown' then
    local route = nil;
    if self.caller.gateway then
      if not common.str.blank(self.caller.gateway.settings.number_source) then
        self.log:debug('INBOUND_NUMBER: number_source: ', self.caller.gateway.settings.number_source, ', number: ', self.caller:to_s(self.caller.gateway.settings.number_source));
        self.caller.destination_number = self.caller:to_s(self.caller.gateway.settings.number_source);
      end

      route =  dialplan.router.Router:new{ log = self.log, database = self.database, caller = self.caller, variables = self.caller }:route_run('inbound', true);
      if route then
        local ignore_keys = {
          id = true,
          gateway = true,
          ['type'] = true,
          channel_variables = true,
        };

        for key, value in pairs(route) do
          if not ignore_keys[key] then
            self.caller[key] = value;
          end
        end

        self.caller.caller_phone_numbers[1] = self.caller.caller_id_number;
      else
        self.log:notice('INBOUND - no route');
      end
    else
      route = dialplan.router.Router:new{ log = self.log, database = self.database, caller = self.caller, variables = self.caller }:route_run('prerouting', true);
      if route then
        local ignore_keys = {
          id = true,
          gateway = true,
          ['type'] = true,
          channel_variables = true,
        };

        for key, value in pairs(route) do
          if not ignore_keys[key] then
            self.caller[key] = value;
          end
        end
      end
    end

    if route then
      if type(route.channel_variables) == 'table' then
        for key, value in pairs(route.channel_variables) do
          self.caller:set_variable(key, value);
        end
      end

      destination = self:destination_new{ ['type'] = route.type, id = route.id, number = route.destination_number }
      self.caller.destination_number = destination.number;
      self.caller.destination = destination;
    elseif not destination or destination.type == 'unknown' then
      destination = self:destination_new{ number = self.caller.destination_number }
      self.caller.destination = destination;
    end
  end

  self.caller:set_variable('default_language', self.caller.language);
  self.caller:set_variable('sound_prefix', common.array.try(self.config, 'sounds.' .. tostring(self.caller.language)));
  self.log:info('DIALPLAN start - caller_id: ',self.caller.caller_id_number, ' "', self.caller.caller_id_name, '" , number: ', destination.number, ', language: ', self.caller.language);

  self.caller.static_caller_id_number = self.caller.caller_id_number;
  self.caller.static_caller_id_name = self.caller.caller_id_name;
  self.caller:set_variable('gs_caller_id_number', self.caller.caller_id_number);
  self.caller:set_variable('gs_caller_id_name', self.caller.caller_id_name);

  local result = { continue = false };
  local loop = self.caller.loop_count;
  while self.caller:ready() and loop < self.max_loops do
    loop = loop + 1;
    self.caller.loop_count = loop;
    
    self.caller.caller_id_number = self.caller.static_caller_id_number;
    self.caller.caller_id_name = self.caller.static_caller_id_name;

     self.log:info('LOOP ', loop,  
    ' - destination: ', destination.type, '=', destination.id, '/', destination.uuid,'@', destination.node_id, 
    ', number: ', destination.number);

    self.caller:set_variable('gs_clir', self.caller.clir);
    self.caller:set_variable('gs_destination_type', destination.type);
    self.caller:set_variable('gs_destination_id', destination.id);
    self.caller:set_variable('gs_destination_uuid', destination.uuid);
    self.caller:set_variable('gs_destination_number', destination.number);
    self.caller:set_variable('gs_destination_node_local', destination.node_local);
    self.caller:set_variable('gs_destination_node_id, ', destination.node_id);

    result = self:switch(destination);
    result = result or { continue = false, code = 502, cause = 'DESTINATION_OUT_OF_ORDER', phrase = 'Destination out of order' }

    if result.call_service then
      self.caller:set_variable('gs_call_service', result.call_service);
    end

    if not result.continue then
      break;
    end

    if result.call_forwarding then
      self.log:info('LOOP ', loop, ' CALL_FORWARDING - service: ', result.call_forwarding.service,
      ', destination: ', result.call_forwarding.type, '=', result.call_forwarding.id, 
      ', number: ', result.call_forwarding.number);

      local auth_account                  = self:object_find{class = destination.type, id = destination.id};
      self.caller.forwarding_number       = destination.number;
      self.caller.forwarding_service      = result.call_forwarding.service;
      self.caller:set_variable('gs_forwarding_service', self.caller.forwarding_service);
      self.caller:set_variable('gs_forwarding_number', self.caller.forwarding_number);

      if auth_account then
        self.caller.auth_account = auth_account;
        self.caller:set_auth_account(self.caller.auth_account);
        self.log:info('AUTH_ACCOUNT_UPDATE - account: ', self.caller.auth_account.class, '=', self.caller.auth_account.id, '/', self.caller.auth_account.uuid);      
        if self.caller.auth_account.owner then
          self.log:info('AUTH_ACCOUNT_UPDATE - auth owner: ', self.caller.auth_account.owner.class, '=', self.caller.auth_account.owner.id, '/', self.caller.auth_account.owner.uuid);
        else
          self.log:error('AUTH_ACCOUNT_UPDATE - auth owner not found');
        end
      end

      destination = self:destination_new(result.call_forwarding);
      self.caller.destination = destination;
      self.caller.destination_number = destination.number;

      if not result.no_cdr and auth_account then
        require 'common.call_history'
        common.call_history.CallHistory:new{ log = self.log, database = self.database }:insert_forwarded(
          self.caller.uuid,
          auth_account.class, 
          auth_account.id, 
          self.caller,
          destination,
          result
        );
        local forwarding_path = self.caller:to_s('gs_forwarding_path');
        if forwarding_path ~= '' then
          forwarding_path = forwarding_path .. ',';
        end

        forwarding_path = forwarding_path .. auth_account.class:sub(1,1) .. ':' .. auth_account.id;
        self.caller:set_variable('gs_forwarding_path', forwarding_path);
        self.log:debug('FORWARDING_PATH: ', forwarding_path);
      end
    end

    if result.number then
      self.log:info('LOOP ', loop, ' NEW_DESTINATION_NUMBER - number: ', result.number );
      destination = self:destination_new{ number = result.number }
      self.caller.destination = destination;
      self.caller.destination_number = destination.number;
    end
  end

  if loop >= self.max_loops then
    result = { continue = false, code = 483, cause = 'EXCHANGE_ROUTING_ERROR', phrase = 'Too many hops' }
  end

  self.log:info('DIALPLAN end - caller_id: ',self.caller.caller_id_number, ' "', self.caller.caller_id_name,'"',
    ', destination: ', destination.type, '=', destination.id, '/', destination.uuid,'@', destination.node_id, 
    ', number: ', destination.number, ', result: ', result.code, ' ', result.phrase);

  if self.caller:ready() then
    self:hangup(result.code, result.phrase, result.cause);
  end

  self.caller:set_variable('gs_save_cdr', not result.no_cdr);
end
