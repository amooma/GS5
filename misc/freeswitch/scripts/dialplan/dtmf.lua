-- Gemeinschaft 5 module: dtmf class
-- (c) AMOOMA GmbH 2013
-- 

module(...,package.seeall)

Dtmf = {}

-- create dtmf object
function Dtmf.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.class = 'Dtmf';
  self.log = arg.log;
  self.bleg = arg.bleg
  self.digit_timeout = arg.digit_timeout or 5;
  self.router = arg.router;

  return object;
end


function Dtmf.detect(self, caller, sequence, digit, duration, calee)
  local timestamp = os.time();
  if timestamp - sequence.updated > self.digit_timeout then
    sequence.digits = digit;
  else
    sequence.digits = sequence.digits .. digit;
  end

  caller.dtmf_digits = sequence.digits;

  if calee then
    self.log:debug('DTMF_RECEIVER callee - digit: [', digit, '][', duration, '], sequence: ', sequence.digits);
  else
    self.log:debug('DTMF_RECEIVER caller - digit: [', digit, '][', duration, '], sequence: ', sequence.digits);
  end

  local route = self.router:route_run('dtmf', true);
  sequence.updated = timestamp;

  if not route then
    return;
  end

  if route.type == 'dialplanfunction' or route.type == 'phonenumber' or route.type == 'unknown' then
    self:transfer(caller, route.destination_number, calee)
  else
    self.log:notice('DTMF_RECEIVER - unhandled destination: ', route.type, '=', route.id);
  end
end


function Dtmf.transfer(self, caller, destination, calee)
  require 'common.fapi'
  local fapi = common.fapi.FApi:new{ log = log };
  local callee_uuid = caller:to_s('bridge_to');
  
  self.log:notice('DTMF_RECEIVER_TRANSFER - destination: ', destination, ', uuid: ', caller.uuid, ', callee_uuid: ', callee_uuid, ', callee_initiated: ', calee);
  if calee then
    caller:execute('transfer', destination);
    fapi:execute('uuid_kill', callee_uuid);
  else
    fapi:execute('uuid_transfer', callee_uuid .. ' ' .. destination);
    caller.session:hangup();
  end
end
