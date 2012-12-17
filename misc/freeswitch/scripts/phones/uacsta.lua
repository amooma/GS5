-- CommonModule: Uacsta
--
module(...,package.seeall)

Uacsta = {}

-- Create Uacsta object
function Uacsta.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self)
  self.__index = self
  self.log = arg.log;

  return object
end

function Uacsta.send(self, sip_account, domain, body)
  local event = freeswitch.Event("NOTIFY");
  event:addHeader("profile", "gemeinschaft");
  event:addHeader("event-string", "uaCSTA");
  event:addHeader("user", sip_account);
  event:addHeader("host", domain);
  event:addHeader("content-type", "application/csta+xml");
  event:addBody(body);
  event:fire();
end

function Uacsta.make_call(self, sip_account, domain, number)
  local body = 
[[<?xml version="1.0" encoding="UTF-8"?> 
<MakeCall xmlns="http://www.ecma-international.org/standards/ecma-323/csta/ed4"> 
  <callingDevice>]] .. sip_account .. [[</callingDevice> 
  <calledDirectoryNumber>]] .. number .. [[</calledDirectoryNumber> 
  <autoOriginate>doNotPrompt</autoOriginate> 
</MakeCall>]]

  self:send(sip_account, domain, body);
end

function Uacsta.answer_call(self, sip_account, domain)
  local body = 
[[<?xml version="1.0" encoding="UTF-8"?> 
<AnswerCall xmlns="http://www.ecma-international.org/standards/ecma-323/csta/ed4">
  <callToBeAnswered>
    <deviceID>]] .. sip_account .. [[</deviceID>
  </callToBeAnswered>
</AnswerCall>]]

  self:send(sip_account, domain, body);
end

function Uacsta.set_microphone_mute(self, sip_account, domain, value)
  local body = 
[[<?xml version="1.0" encoding="UTF-8"?> 
<SetMicrophoneMute xmlns="http://www.ecma-international.org/standards/ecma-323/csta/ed3">
  <device>]] .. sip_account .. [[</device>
  <auditoryApparatus>1</auditoryApparatus>
  <microphoneMuteOn>]] .. tostring(value) .. [[</microphoneMuteOn>
</SetMicrophoneMute>]]

  self:send(sip_account, domain, body);
end

function Uacsta.set_speaker_volume(self, sip_account, domain, value)
  local body = 
[[<?xml version="1.0" encoding="UTF-8"?> 
<SetSpeakerVolume xmlns="http://www.ecma-international.org/standards/ecma-323/csta/ed3">
  <device>]] .. sip_account .. [[</device>
  <auditoryApparatus>1</auditoryApparatus>
  <speakerVolume>]] .. tonumber(value) .. [[</speakerVolume>
</SetSpeakerVolume>]]

  self:send(sip_account, domain, body);
end

function Uacsta.set_do_not_disturb(self, sip_account, domain, value)
  local body = 
[[<?xml version="1.0" encoding="UTF-8"?> 
<SetDoNotDisturb xmlns="http://www.ecma-international.org/standards/ecma-323/csta/ed3">
  <device>]] .. sip_account .. [[</device>
  <doNotDisturbOn>]] .. tostring(value) .. [[</doNotDisturbOn>
</SetDoNotDisturb>]]

  self:send(sip_account, domain, body);
end

function Uacsta.set_forwarding(self, sip_account, domain, forwarding_type, number, activate)
  local forwarding_types = { "forwardImmediate", "forwardBusy", "forwardNoAns" }
  local body = 
[[<?xml version="1.0" encoding="UTF-8"?> 
<SetForwarding xmlns="http://www.ecma-international.org/standards/ecma-323/csta/ed3">
  <device>]] .. sip_account .. [[</device>
  <forwardingType>]] .. tostring(forwarding_types[tonumber(forwarding_type)]) .. [[</forwardingType>
  <forwardDN>]] .. number .. [[</forwardDN>
  <activateForward>]] .. tostring(activate) .. [[</activateForward>
</SetForwarding>]]

  self:send(sip_account, domain, body);
end
