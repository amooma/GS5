class Uacsta

  def send(sip_account, domain, body)
    require 'freeswitch_event'

    event = FreeswitchEvent.new("NOTIFY")
    event.add_header("profile", "gemeinschaft")
    event.add_header("event-string", "uaCSTA")
    event.add_header("user", sip_account)
    event.add_header("host", domain)
    event.add_header("content-type", "application/csta+xml")
    event.add_body(body);

    return event.fire();
  end

  def make_call(sip_account, domain, number)
    body = '<?xml version="1.0" encoding="UTF-8"?> 
  <MakeCall xmlns="http://www.ecma-international.org/standards/ecma-323/csta/ed4"> 
    <callingDevice>' + sip_account.to_s + '</callingDevice> 
    <calledDirectoryNumber>' + number.to_s + '</calledDirectoryNumber> 
    <autoOriginate>doNotPrompt</autoOriginate> 
  </MakeCall>'

    self.send(sip_account, domain, body);
  end

  def answer_call(sip_account, domain)
    body = '<?xml version="1.0" encoding="UTF-8"?> 
  <AnswerCall xmlns="http://www.ecma-international.org/standards/ecma-323/csta/ed4">
    <callToBeAnswered>
      <deviceID>' + sip_account + '</deviceID>
    </callToBeAnswered>
  </AnswerCall>'

    self.send(sip_account, domain, body)
  end

  def set_microphone_mute(sip_account, domain, value)
    body = '<?xml version="1.0" encoding="UTF-8"?> 
  <SetMicrophoneMute xmlns="http://www.ecma-international.org/standards/ecma-323/csta/ed3">
    <device>' + sip_account + '</device>
    <auditoryApparatus>1</auditoryApparatus>
    <microphoneMuteOn>' + value.to_s + '</microphoneMuteOn>
  </SetMicrophoneMute>'

    self.send(sip_account, domain, body)
  end

  def set_speaker_volume(sip_account, domain, value)
    body = '<?xml version="1.0" encoding="UTF-8"?> 
  <SetSpeakerVolume xmlns="http://www.ecma-international.org/standards/ecma-323/csta/ed3">
    <device>' + sip_account + '</device>
    <auditoryApparatus>1</auditoryApparatus>
    <speakerVolume>' + value.to_s + '</speakerVolume>
  </SetSpeakerVolume>'

    self.send(sip_account, domain, body)
  end

  def set_do_not_disturb(sip_account, domain, value)
    body = '<?xml version="1.0" encoding="UTF-8"?> 
  <SetDoNotDisturb xmlns="http://www.ecma-international.org/standards/ecma-323/csta/ed3">
    <device>' + sip_account + '</device>
    <doNotDisturbOn>' + value.to_s + '</doNotDisturbOn>
  </SetDoNotDisturb>'

    self.send(sip_account, domain, body)
  end

  def set_forwarding(sip_account, domain, forwarding_type, number, activate)
    forwarding_types = [ "forwardImmediate", "forwardBusy", "forwardNoAns" ]
    body = '<?xml version="1.0" encoding="UTF-8"?> 
  <SetForwarding xmlns="http://www.ecma-international.org/standards/ecma-323/csta/ed3">
    <device>' + sip_account + '</device>
    <forwardingType>' + forwarding_types[forwarding_type.to_i] + '</forwardingType>
    <forwardDN>' + number.to_s + '</forwardDN>
    <activateForward>' + activate.to_s + '</activateForward>
  </SetForwarding>'

    self.send(sip_account, domain, body)
  end
end
