# -*- coding: utf-8 -*-
# MonAMI Asterisk Manger Interface Server
# Asterisk AMI Emulator Handler Process
# (c) AMOOMA GmbH 2012

from threading import Thread
from log import ldebug, linfo, lwarn, lerror, lcritic
from time import sleep
from traceback import format_exc
from collections import deque
from urllib import unquote
from asterisk import AsteriskAMIServer
from socket import SHUT_RDWR
from helper import sval


class MonAMIHandler(Thread):

  def __init__(self, socket, address, event_socket=None):
    Thread.__init__(self)
    self.runthread = True
    self.socket = socket
    self.address = address
    self.event_socket = event_socket
    self.ami = None
    self.deregister_at_server = None
    self.message_pipe = deque()
    self.channels = {}
    self.user_password_authentication = None
    self.account_name = ''


  def stop(self):
    ldebug('thread stop', self)
    self.ami.stop()
    self.runthread = False


  def shutdown(self):
    self.deregister_at_server(self)
    ldebug('closing connection to %s:%d' % self.address)
    try:
      self.socket.shutdown(SHUT_RDWR)
      self.socket.close()
      ldebug('connection closed ', self)
    except:
      ldebug('connection closed by foreign host', self)
  
  def run(self):
    ldebug('starting MonAMI handler thread', self)

    # starting asterisk AMI thread
    self.ami = AsteriskAMIServer(self.socket, self.address, self.message_pipe)
    self.ami.start()
    self.ami.send_greeting()

    # register for events
    self.event_socket.register_client_queue(self.message_pipe, 'CHANNEL_CREATE')
    self.event_socket.register_client_queue(self.message_pipe, 'CHANNEL_DESTROY')
    self.event_socket.register_client_queue(self.message_pipe, 'CHANNEL_STATE')
    self.event_socket.register_client_queue(self.message_pipe, 'CHANNEL_ANSWER')
    self.event_socket.register_client_queue(self.message_pipe, 'CHANNEL_BRIDGE')

    while self.runthread and self.ami.isAlive():
      if self.message_pipe:
        message = self.message_pipe.pop()
        message_type = sval(message, 'type')
        if message_type == 'freeswitch_event':
          self.handle_fs_event(message['body'])
        elif message_type == 'ami_client_message':
          self.handle_ami_client_message(message['body'])
      else:
        sleep(0.1)

    self.event_socket.deregister_client_queue_all(self.message_pipe)

    ldebug('exiting MonAMI handler thread', self)
    self.shutdown()


  def handle_ami_client_message(self, message):

    if 'Action' in message:
      action = message['Action'].lower()
      
      if action == 'login':
        if 'UserName' in message:
          self.account_name = message['UserName']
        if 'Secret' in message and self.user_password_authentication and self.user_password_authentication(self.account_name, message['Secret']):
          self.ami.send_login_ack()
          ldebug('AMI connection authenticated - account: %s' % self.account_name, self)
        else:
          self.ami.send_login_nack()
          linfo('AMI authentication failed - account: %s' % sval(message, 'UserName'), self)
          self.ami.stop()
          self.stop()
      elif action == 'logoff':
        self.ami.send_logout_ack()
        ldebug('AMI logout', self)
        self.ami.stop()
        self.stop()
      elif action == 'ping':
        self.ami.send_pong(sval(message, 'ActionID'))
      elif action == 'status':
        self.ami.send_status_ack(sval(message, 'ActionID'))
      elif action == 'command' and sval(message, 'Command') == 'core show version':
        self.ami.send_asterisk_version(sval(message, 'ActionID'))
      elif action == 'hangup':
        account_name, separator, uuid = str(sval(message, 'Channel')).rpartition('-uuid-')
        if account_name != '':
          self.event_socket.hangup(uuid)
          self.ami.send_hangup_ack()
      elif action == 'originate':
        self.message_originate(message)
      elif action == 'extensionstate':
        self.ami.send_extension_state(sval(message, 'ActionID'), sval(message, 'Exten'), sval(message, 'Context'))
      else:
        ldebug('unknown asterisk message received: %s' % message, self)
        self.ami.send_message_unknown(message['Action'])


  def to_unique_channel_name(self, uuid, channel_name):

    # strip anything left of sip_account_name
    path, separator, contact_part = channel_name.rpartition('/sip:')
    if path == '':
      path, separator, contact_part = channel_name.rpartition('/')

    # if failed return name unchanged
    if path == '':
      return channel_name


    # strip domain part
    account_name = contact_part.partition('@')[0]

    # if failed return name unchanged
    if account_name == '':
      return channel_name

    # create unique channel name
    return 'SIP/%s-uuid-%s' % (account_name, uuid)

  def message_originate(self, message):
    destination_number = str(sval(message, 'Exten'))
    action_id = sval(message, 'ActionID')
    self.ami.send_originate_ack(action_id)
    uuid = self.event_socket.originate(self.account_name, destination_number, action_id)


  def handle_fs_event(self, event):
    event_type = event['Event-Name']
    #ldebug('event type received: %s' % event_type, self)

    event_types = {
      'CHANNEL_CREATE':   self.event_channel_create,
      'CHANNEL_DESTROY':  self.event_channel_destroy,
      'CHANNEL_STATE':    self.event_channel_state,
      'CHANNEL_ANSWER':   self.event_channel_answer,
      'CHANNEL_BRIDGE':   self.event_channel_bridge,
    }

    uuid = event_types[event_type](event)

    if not uuid:
      return False

    channel = sval(self.channels, uuid);

    if not channel:
      return False

    o_uuid = channel['o_uuid']
    o_channel = sval(self.channels, o_uuid);

    if sval(channel, 'origination_action') or sval(o_channel, 'origination_action'):
      if not sval(channel, 'ami_start') and not sval(o_channel, 'ami_start'):
        if sval(channel, 'owned') and sval(channel, 'origination_action'):
          ldebug('sending AMI events for origitate call start (on this channel): %s' % uuid, self)
          self.ami_send_originate_start(channel)
          self.channels[uuid]['ami_start'] = True
        elif sval(o_channel, 'owned') and sval(o_channel, 'origination_action'):
          ldebug('sending AMI events for origitate call start (on other channel): %s' % uuid, self)
          self.ami_send_originate_start(o_channel)
          self.channels[o_uuid]['ami_start'] = True
      elif o_channel:
        if sval(channel, 'owned') and sval(channel, 'origination_action'):
          ldebug('sending AMI events for origitate call progress (on this channel): %s' % uuid, self)
          self.ami_send_originate_outbound(channel)
          self.channels[uuid]['origination_action'] = False
        elif sval(o_channel, 'owned') and sval(o_channel, 'origination_action'):
          ldebug('sending AMI events for origitate call progress (on other channel): %s' % uuid, self)
          self.ami_send_originate_outbound(o_channel)
          self.channels[o_uuid]['origination_action'] = False
    elif o_channel:
      if not sval(channel, 'ami_start') and not sval(o_channel, 'ami_start'):
        if sval(channel, 'owned') and sval(channel, 'direction') == 'inbound':
          ldebug('sending AMI events for outbound call start (on this channel): %s' % uuid, self)
          self.ami_send_outbound_start(channel)
          self.channels[uuid]['ami_start'] = True
        elif sval(o_channel, 'owned') and sval(channel, 'direction') == 'outbound':
          ldebug('sending AMI events for outbound call start (on other channel): %s' % uuid, self)
          self.ami_send_outbound_start(o_channel)
          self.channels[o_uuid]['ami_start'] = True
      
      if not sval(channel, 'ami_start')and not sval(o_channel, 'ami_start'):
        if sval(channel, 'owned') and sval(channel, 'direction') == 'outbound':
          ldebug('sending AMI events for inbound call start (on this channel): %s' % uuid, self)
          self.ami_send_inbound_start(channel)
          self.channels[uuid]['ami_start'] = True
        elif sval(o_channel, 'owned') and sval(channel, 'direction') == 'inbound':
          ldebug('sending AMI events for inbound call start (on other channel): %s' % uuid, self)
          self.ami_send_inbound_start(o_channel)
          self.channels[o_uuid]['ami_start'] = True


  def event_channel_create(self, event):
    uuid = sval(event, 'Unique-ID')
    o_uuid = sval(event, 'Other-Leg-Unique-ID')

    if uuid in self.channels:
      ldebug('channel already listed: %s' % uuid, self)
      return false

    channel_name = self.to_unique_channel_name(uuid, unquote(str(sval(event, 'Channel-Name'))))
    o_channel_name = self.to_unique_channel_name(o_uuid, unquote(str(sval(event, 'Other-Leg-Channel-Name'))))

    if self.account_name in channel_name:
      channel_owned = True
    else:
      channel_owned = False

    if self.account_name in o_channel_name:
      channel_related = True
    else:
      channel_related = False

    if not channel_owned and not channel_related:
      ldebug('channel neither owned nor reladed to account: %s' % uuid, self)
      return False
    
    channel = {
      'uuid':               uuid,
      'name':               channel_name,
      'direction':          sval(event, 'Call-Direction'),
      'channel_state':      sval(event, 'Channel-State'),
      'call_state':         sval(event, 'Channel-Call-State'),
      'answer_state':       sval(event, 'Answer-State'),
      'owned':              channel_owned,
      'related':            channel_related,
      'caller_id_name':     unquote(str(sval(event, 'Caller-Caller-ID-Name'))),
      'caller_id_number':   unquote(str(sval(event, 'Caller-Caller-ID-Number'))),
      'callee_id_name':     unquote(str(sval(event, 'Caller-Callee-ID-Name'))),
      'callee_id_number':   unquote(str(sval(event, 'Caller-Callee-ID-Number'))),
      'destination_number': str(sval(event, 'Caller-Destination-Number')),
      'origination_action': sval(event, 'variable_origination_action'),
      'o_uuid': o_uuid,
      'o_name': o_channel_name,            
    }

    if channel['answer_state'] == 'ringing':
      if channel['direction'] == 'inbound':
        asterisk_channel_state = 4
      else:
        asterisk_channel_state = 5
    else:
      asterisk_channel_state = 0

    if not o_uuid:
      ldebug('one legged call, channel: %s' % uuid, self)
    elif o_uuid not in self.channels:
      o_channel = {
        'uuid':               o_uuid,
        'name':               o_channel_name,
        'direction':          sval(event, 'Other-Leg-Direction'),
        'channel_state':      sval(event, 'Channel-State'),
        'call_state':         sval(event, 'Channel-Call-State'),
        'answer_state':       sval(event, 'Answer-State'),
        'owned':              channel_related,
        'related':            channel_owned,
        'caller_id_name':     unquote(str(sval(event, 'Caller-Caller-ID-Name'))),
        'caller_id_number':   unquote(str(sval(event, 'Caller-Caller-ID-Number'))),
        'callee_id_name':     unquote(str(sval(event, 'Caller-Callee-ID-Name'))),
        'callee_id_number':   unquote(str(sval(event, 'Caller-Callee-ID-Number'))),
        'destination_number': str(sval(event, 'Other-Leg-Destination-Number')),
        'o_uuid': uuid,
        'o_name': channel_name,            
      }

      if o_channel['answer_state'] == 'ringing':
        if o_channel['direction'] == 'inbound':
          asterisk_o_channel_state = 4
        else:
          asterisk_o_channel_state = 5
      else:
        asterisk_o_channel_state = 0

      ldebug('create channel list entry for related channel: %s, name: %s' % (o_uuid, o_channel_name), self)
      self.channels[o_uuid] = o_channel
    else:
      ldebug('updating channel: %s, name: %s, o_uuid: %s, o_name %s' % (o_uuid, o_channel_name, uuid, channel_name), self)
      self.channels[o_uuid]['o_uuid'] = uuid
      self.channels[o_uuid]['o_name'] = channel_name
      o_channel = self.channels[o_uuid]

    if channel_owned:
      ldebug('create channel list entry for own channel: %s, name: %s' % (uuid, channel_name), self)
    elif channel_related:
      ldebug('create channel list entry for related channel: %s, name: %s' % (uuid, channel_name), self)
    
    self.channels[uuid] = channel
      
    return uuid
    

  def event_channel_destroy(self, event):
    uuid = sval(event, 'Unique-ID')
    hangup_cause_code = int(sval(event, 'variable_hangup_cause_q850'))
    channel = sval(self.channels, uuid)

    if channel:
      channel['hangup_cause_code'] = hangup_cause_code
      if sval(channel, 'ami_start'):
        self.ami_send_outbound_end(channel)
      del self.channels[uuid]
      ldebug('channel removed from list: %s, cause %d' % (uuid, hangup_cause_code), self)

    return uuid


  def event_channel_state(self, event): 
    uuid = sval(event, 'Unique-ID')
    channel_state = sval(event, 'Channel-State')
    call_state    = sval(event, 'Channel-Call-State')
    answer_state  = sval(event, 'Answer-State')

    if sval(self.channels, uuid) and False:
      ldebug('updating channel state - channel: %s, channel_state: %s, call_state %s, answer_state: %s' % (uuid, channel_state, call_state, answer_state), self)
      self.channels[uuid]['channel_state'] = channel_state
      self.channels[uuid]['call_state']    = call_state
      self.channels[uuid]['answer_state']  = answer_state

    return uuid


  def event_channel_answer(self, event):
    uuid = sval(event, 'Unique-ID')
    o_uuid = sval(event, 'Other-Leg-Unique-ID')
    channel = sval(self.channels, uuid)
    if not o_uuid:
      o_uuid = sval(channel, 'o_uuid')
    o_channel = sval(self.channels, o_uuid)
    origination_action = sval(channel, 'origination_action')

    if channel:
      channel_state = sval(event, 'Channel-State')
      call_state    = sval(event, 'Channel-Call-State')
      answer_state  = sval(event, 'Answer-State')
      ldebug('channel answered - channel: %s, owned: %s, channel_state: %s, call_state %s, answer_state: %s, other leg: %s' % (uuid, sval(channel, 'owned'), channel_state, call_state, answer_state, o_uuid), self)
      self.ami.send_event_newstate(uuid, sval(channel, 'name'), 6, sval(channel, 'caller_id_number'), sval(channel, 'caller_id_name'))

      self.channels[uuid]['channel_state'] = channel_state
      self.channels[uuid]['call_state']    = call_state
      self.channels[uuid]['answer_state']  = answer_state

      if sval(channel, 'origination_action'):
        if sval(channel, 'owned'):
          ldebug('sending AMI originate response - success: %s' % uuid, self)
          self.ami.send_event_originate_response(sval(channel, 'uuid'), sval(channel, 'name'), sval(channel, 'caller_id_number'), sval(channel, 'caller_id_name'), '101', sval(channel, 'origination_action'), 4)
      elif not o_uuid:
        ldebug('sending AMI events for outbound call start on one legged call (this channel): %s' % uuid, self)
        self.ami_send_outbound_start(channel)
        self.ami.send_event_bridge(uuid, sval(channel, 'name'), sval(channel, 'caller_id_number'), o_uuid, sval(o_channel, 'name'), sval(o_channel, 'caller_id_number'))

        self.channels[uuid]['ami_start'] = True
      
      return uuid
    
    return False

     
  def event_channel_bridge(self, event):
    uuid = sval(event, 'Unique-ID')
    o_uuid = sval(event, 'Other-Leg-Unique-ID')

    ldebug('bridge channel: %s to %s' % (uuid, o_uuid), self)
    channel = sval(self.channels, uuid)
    o_channel = sval(self.channels, o_uuid)

    if sval(channel, 'owned') or sval(o_channel, 'owned'):
      ldebug('sending AMI bridge response: %s -> %s' % (uuid, o_uuid), self)
      self.ami.send_event_bridge(uuid, sval(channel, 'name'), sval(channel, 'caller_id_number'), o_uuid, sval(o_channel, 'name'), sval(o_channel, 'caller_id_number'))


  def ami_send_outbound_start(self, channel):
    self.ami.send_event_newchannel(sval(channel, 'uuid'), sval(channel, 'name'), 0, sval(channel, 'caller_id_number'), sval(channel, 'caller_id_name'), sval(channel, 'destination_number'))
    self.ami.send_event_newstate(sval(channel, 'uuid'), sval(channel, 'name'), 4, sval(channel, 'caller_id_number'), sval(channel, 'caller_id_name'))
    self.ami.send_event_newchannel(sval(channel, 'o_uuid'), sval(channel, 'o_name'), 0, '', '', '')
    self.ami.send_event_dial_begin(sval(channel, 'uuid'), sval(channel, 'name'), sval(channel, 'caller_id_number'), sval(channel, 'caller_id_name'), sval(channel, 'o_name'), sval(channel, 'o_uuid'), sval(channel, 'destination_number'))
    self.ami.send_event_newcallerid(sval(channel, 'o_uuid'), sval(channel, 'o_name'), sval(channel, 'destination_number'), '', 0)
    self.ami.send_event_newstate(sval(channel, 'o_uuid'), sval(channel, 'o_name'), 5, sval(channel, 'destination_number'), '')


  def ami_send_outbound_end(self, channel):
    self.ami.send_event_hangup(sval(channel, 'o_uuid'), sval(channel, 'o_name'), sval(channel, 'destination_number'), '', sval(channel, 'hangup_cause_code'))
    self.ami.send_event_dial_end(sval(channel, 'uuid'), sval(channel, 'name'))
    self.ami.send_event_hangup(sval(channel, 'uuid'), sval(channel, 'name'), sval(channel, 'caller_id_number'), sval(channel, 'caller_id_name'), sval(channel, 'hangup_cause_code'))

    if sval(channel, 'origination_action'):
      self.ami.send_event_originate_response(sval(channel, 'uuid'), sval(channel, 'name'), sval(channel, 'caller_id_number'), sval(channel, 'caller_id_name'), sval(channel, 'destination_number'), sval(channel, 'origination_action'), 1)
 

  def ami_send_inbound_start(self, channel):
    self.ami.send_event_newchannel(sval(channel, 'o_uuid'), sval(channel, 'o_name'), 0, sval(channel, 'caller_id_number'), sval(channel, 'caller_id_name'), sval(channel, 'callee_id_number'))
    self.ami.send_event_newstate(sval(channel, 'o_uuid'), sval(channel, 'o_name'), 4, sval(channel, 'caller_id_number'), sval(channel, 'caller_id_name'))
    self.ami.send_event_newchannel(sval(channel, 'uuid'), sval(channel, 'name'), 0, '', '', '')
    self.ami.send_event_dial_begin(sval(channel, 'o_uuid'), sval(channel, 'o_name'), sval(channel, 'caller_id_number'), sval(channel, 'caller_id_name'), sval(channel, 'name'), sval(channel, 'uuid'), sval(channel, 'destination_number'))
    self.ami.send_event_newstate(sval(channel, 'uuid'), sval(channel, 'name'), 5, sval(channel, 'caller_id_number'), sval(channel, 'caller_id_name'))
    self.ami.send_event_newcallerid(sval(channel, 'uuid'), sval(channel, 'name'), sval(channel, 'destination_number'), '', 0)


  def ami_send_originate_start(self, channel):
    self.ami.send_event_newchannel(sval(channel, 'uuid'), sval(channel, 'name'), 0, '', '', '')
    self.ami.send_event_newcallerid(sval(channel, 'uuid'), sval(channel, 'name'), sval(channel, 'caller_id_number'), sval(channel, 'caller_id_name'), 0)
    self.ami.send_event_newaccountcode(sval(channel, 'uuid'), sval(channel, 'name'))
    self.ami.send_event_newcallerid(sval(channel, 'uuid'), sval(channel, 'name'), sval(channel, 'caller_id_number'), sval(channel, 'caller_id_name'), 0)
    self.ami.send_event_newstate(sval(channel, 'uuid'), sval(channel, 'name'), 5, sval(channel, 'caller_id_number'), sval(channel, 'caller_id_name'))


  def ami_send_originate_outbound(self, channel):
    self.ami.send_event_newchannel(sval(channel, 'o_uuid'), sval(channel, 'o_name'), 0, '', '', '')
    self.ami.send_event_dial_begin(sval(channel, 'uuid'), sval(channel, 'name'), sval(channel, 'caller_id_number'), sval(channel, 'caller_id_name'), sval(channel, 'o_name'), sval(channel, 'o_uuid'), sval(channel, 'destination_number'))
    self.ami.send_event_newcallerid(sval(channel, 'o_uuid'), sval(channel, 'o_name'), sval(channel, 'destination_number'), '', 0)
    self.ami.send_event_newstate(sval(channel, 'o_uuid'), sval(channel, 'o_name'), 5, sval(channel, 'destination_number'), '')
