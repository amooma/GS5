-- Gemeinschaft 5 module: call_history event handler class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

function handler_class()
  return CallHistorySave
end

CallHistorySave = {}


function CallHistorySave.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.log = arg.log;
  self.class = 'callhistorysave'
  self.database = arg.database;
  self.domain = arg.domain;

  return object;
end


function CallHistorySave.event_handlers(self)
  return { CHANNEL_DESTROY = { [true] = self.channel_destroy } }
end


function CallHistorySave.channel_destroy(self, event)
  local uuid = event:getHeader('Unique-ID');
  local direction = event:getHeader('variable_direction');

  require 'common.str'
  local save_cdr = common.str.to_b(event:getHeader('variable_gs_save_cdr'));

  if not save_cdr then
    self.log:debug('[', uuid,'] CALL_HISTORY_SAVE - event: CHANNEL_DESTROY, direction: ', direction, ', save_cdr: ', save_cdr);
    return false;
  end

  require 'common.call_history'
  call_history_class = common.call_history.CallHistory:new{ log = self.log, database = self.database }
    
  -- caller entry
  local account_type = event:getHeader('variable_gs_account_type');
  local account_id = common.str.to_i(event:getHeader('variable_gs_account_id'));

  if account_type and account_id > 0 and common.str.to_b(event:getHeader('variable_gs_account_node_local')) then
    call_history_class:insert_event(uuid, account_type, account_id, 'dialed', event);
  else
    self.log:info('[', uuid,'] CALL_HISTORY_SAVE - ignore caller entry - account: ', account_type, '=', account_id, ', local: ', event:getHeader('variable_gs_account_node_local'));
  end

  -- callee entry
  local account_type = event:getHeader('variable_gs_destination_type');
  local account_id = common.str.to_i(event:getHeader('variable_gs_destination_id'));

  if account_type and account_id > 0 
    and common.str.to_b(event:getHeader('variable_gs_destination_node_local')) 
    and tostring(event:getHeader('variable_gs_call_service')) ~= 'pickup' then

    if tostring(event:getHeader('variable_endpoint_disposition')) == 'ANSWER' then
      call_history_class:insert_event(uuid, account_type, account_id, 'received', event);
    else
      call_history_class:insert_event(uuid, account_type, account_id, 'missed', event);
    end
  else
    self.log:info('[', uuid,'] CALL_HISTORY_SAVE - ignore callee entry - account: ', account_type, '=', account_id, ', local: ', event:getHeader('variable_gs_destination_node_local'));
  end
end
