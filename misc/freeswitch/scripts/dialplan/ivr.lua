-- Gemeinschaft 5 module: ivr class
-- (c) AMOOMA GmbH 2013
-- 

module(...,package.seeall)

Ivr = {}

-- create ivr ivr ;)
function Ivr.new(self, arg)
  arg = arg or {}
  ivr = arg.ivr or {}
  setmetatable(ivr, self);
  self.__index = self;
  self.class = 'ivr';
  self.log = arg.log;
  self.caller = arg.caller;
  self.dtmf_threshold = arg.dtmf_threshold or 500;

  return ivr;
end


function Ivr.ivr_break(self)
  return self.exit or not self.caller:ready();
end


function Ivr.ivr_phrase(self, phrase, keys, timeout, ivr_repeat, phrase_data)
  ivr_repeat = ivr_repeat or 3;
  timeout = timeout or 30;
  self.digit = '';
  self.exit = false;

  self.break_keys = {};
  local query_keys = {};

  for index=1, #keys do
    if type(keys[index]) == 'table' then
      if tostring(keys[index].key) ~= '' then
        table.insert(query_keys, keys[index].key);
      end
      self.break_keys[keys[index].key] = keys[index];
    else
      if tostring(keys[index]) ~= '' then
        table.insert(query_keys, keys[index]);
      end
      self.break_keys[keys[index]] = true;
    end
  end

  global_callback:callback('dtmf', 'ivr_ivr_phrase', self.ivr_phrase_dtmf, self);
  local continue = true;
  for index=0, ivr_repeat do
    continue = self:ivr_break() or self.caller.session:sayPhrase(phrase, phrase_data or table.concat(query_keys, ':'));
    continue = self:ivr_break() or self.caller:sleep(timeout * 1000);

    if self:ivr_break() then
      break;
    end
  end

  global_callback:callback_unset('dtmf', 'ivr_ivr_phrase');

  if type(self.break_keys[self.digit]) == 'table' then
    return self.digit, self.break_keys[self.digit];
  end

  return self.digit;
end


function Ivr.ivr_phrase_dtmf(self, dtmf)
  if self.break_keys[dtmf.digit] then
    self.digit = dtmf.digit;
    self.exit = true;
    return false;
  end
end


function Ivr.read_phrase(self, phrase, phrase_data, max_keys, min_keys, timeout, key_terminator)
  self.max_keys = max_keys or 64;
  self.min_keys = min_keys or 1;
  self.key_terminator = key_terminator or '#';
  self.digits = '';
  self.exit = false;
  timeout = timeout or 30;

  global_callback:callback('dtmf', 'ivr_read_phrase', self.read_phrase_dtmf, self);
  local continue = self:ivr_break() or self.caller.session:sayPhrase(phrase, phrase_data or key_terminator or '');
  continue = self:ivr_break() or self.caller:sleep(timeout * 1000);
  global_callback:callback_unset('dtmf', 'ivr_read_phrase');

  return self.digits;
end


function Ivr.read_phrase_dtmf(self, dtmf)
  if dtmf.duration < self.dtmf_threshold then
    return nil;
  end

  if self.key_terminator == dtmf.digit then
    self.exit = true;
    return false;
  end

  self.digits = self.digits .. dtmf.digit;
end


function Ivr.check_pin(self, phrase_enter, phrase_incorrect, pin, pin_timeout, pin_repeat, key_terminator)
  if not pin then
    return nil;
  end

  self.exit = false;
  pin_timeout = pin_timeout or 30;
  pin_repeat = pin_repeat or 3;
  key_terminator = key_terminator or '#';

  local digits = '';
  for i = 1, pin_repeat do
    if digits == pin then
      self.caller:send_display('PIN: OK');
      break;
    elseif digits ~= "" then
      self.caller:send_display('PIN: wrong');
      self.caller.session:sayPhrase(phrase_incorrect, '');
    elseif self:ivr_break() then
      break;
    end
    self.caller:send_display('Enter PIN');
    digits = ivr:read_phrase(phrase_enter, nil, 0, pin:len() + 1, pin_timeout, key_terminator);
  end

  if digits ~= pin then
    self.caller:send_display('PIN: wrong');
    self.caller.session:sayPhrase(phrase_incorrect, '');
    return false
  end
  self.caller:send_display('PIN: OK');

  return true;
end


function Ivr.record(self, file_name, beep, phrase_record, phrase_too_short, record_length_max, record_length_min, record_repeat, silence_level, silence_lenght_abort)
  local duration = nil;
  for index=1, record_repeat do
    if (duration and duration >= record_length_min) or not self.caller:ready() then
      break;
    elseif duration then
      self.caller:send_display('Recording too short');
      if phrase_too_short then
        self.caller.session:sayPhrase(phrase_too_short);
      end
    end
    if phrase_record then
      self.caller.session:sayPhrase(phrase_record);
    end
    if beep then
      self.caller:playback(beep);
    end
    self.caller:send_display('Recording...');
    local result = self.caller.session:recordFile(file_name, record_length_max, silence_level, silence_lenght_abort);
    duration = self.caller:to_i('record_seconds');
  end

  return duration or 0;
end
