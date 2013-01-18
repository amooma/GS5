# -*- coding: utf-8 -*-
# MonAMI Asterisk Manger Interface Server
# Asterisk AMI client connector
# (c) AMOOMA GmbH 2012-2013

from threading import Thread, Lock
from log import ldebug, linfo, lwarn, lerror, lcritic
from time import sleep
from traceback import format_exc
from helper import to_hash
import socket

class AsteriskAMIServer(Thread):

  def __init__(self, client_socket, address, message_queue):
    Thread.__init__(self)
    self.runthread = True
    self.LINE_SEPARATOR = "\r\n"
    self.GREETING_STRING = 'Asterisk Call Manager/1.1'
    self.ASTERISK_VERSION_STRING = 'Asterisk 1.6.2.9-2'
    self.ASTERISK_CHANNEL_STATES = (
      'Down',  
      'Reserved',
      'Offhook',
      'Dialing',
      'Ring',
      'Ringing',
      'Up',
      'Busy',
      'Dialing_Offhook',
      'Pprering',
      'Mute',
    )
    self.ASTERISK_PRESENTATION_INDICATOR = (
      'Presentation allowed',
      'Presentation restricted',
      'Number not available due to interworking',
      'Reserved',
    )
    self.ASTERISK_SCREENING_INDICATOR = (
      'not screened',
      'verified and passed',
      'verified and failed',
      'Network provided',
    )

    self.write_lock = Lock()
    self.socket = client_socket
    self.address = address
    self.message_queue = message_queue


  def stop(self):
    ldebug('thread stop', self)
    self.runthread = False

  
  def run(self):
    ldebug('starting AMI server thread', self)
    
    data = ''
    while self.runthread and self.socket:
      try:
        recv_buffer = self.socket.recv(128)
      except socket.timeout as exception:
        # Socket timeout occured
        continue
      except:
        lerror(format_exc(), self)
        self.runthread = False
        break

      if not recv_buffer:
        ldebug('client connection lost', self)
        break

      data += recv_buffer
      messages = data.split(self.LINE_SEPARATOR * 2)
      data = messages.pop()

      for message_str in messages:
        if not message_str:
          continue
        
        message = to_hash(message_str.split(self.LINE_SEPARATOR))
        self.message_queue.appendleft({'type': 'ami_client_message', 'body': message})

    ldebug('exiting AMI server thread', self)


  def send(self, send_buffer):
    try:
      self.write_lock.acquire()
      self.socket.send(send_buffer)
      self.write_lock.release()
      return True
    except:
      return False


  def send_message(self, *message):
    if len(message) == 1 and type(message[0]) == list:
      self.send(self.LINE_SEPARATOR.join(message[0]) + (self.LINE_SEPARATOR * 2))
    else:
      self.send(self.LINE_SEPARATOR.join(message) + (self.LINE_SEPARATOR * 2))

  def send_greeting(self):
    self.send_message(self.GREETING_STRING)

  def send_message_unknown(self, command):
    self.send_message('Response: Error', 'Message: Invalid/unknown command: %s.' % command)

  def send_login_ack(self):
    self.send_message('Response: Success', 'Message: Authentication accepted')

  def send_login_nack(self):
    self.send_message('Response: Error', 'Message: Authentication failed')

  def send_logout_ack(self):
    self.send_message('Response: Goodbye', 'Message: Thank you for flying MonAMI')

  def send_pong(self, action_id):
    self.send_message('Response: Pong', "ActionID: %s" % str(action_id), 'Server: localhost')

  def send_asterisk_version(self, action_id):
    self.send_message(
      'Response: Follows',
      'Privilege: Command',
      "ActionID: %s" % str(action_id),
      self.ASTERISK_VERSION_STRING,
      '--END COMMAND--'
    )

  def send_hangup_ack(self):
    self.send_message('Response: Success', 'Message: Channel Hungup')


  def send_originate_ack(self, action_id):
    self.send_message('Response: Success', "ActionID: %s" % str(action_id), 'Message: Originate successfully queued')


  def send_status_ack(self, action_id):
    self.send_message(
      'Response: Success',
      "ActionID: %s" % str(action_id),
      'Message: Channel status will follow'
    )
    self.send_message(
      'Event: StatusComplete',
      "ActionID: %s" % action_id,
      'Items: 0'
    )

  def send_extension_state(self, action_id, extension, context = 'default', status = -1, hint = ''):
    self.send_message(
      'Response: Success',
      "ActionID: %s" % str(action_id),
      'Message: Extension Status',
      'Exten: %s' % extension,
      'Context: %s' % context,
      'Hint: %s' % hint,
      'Status: %d' % status,
    )


  def send_event_newchannel(self, uuid, channel_name, channel_state, caller_id_number = '', caller_id_name = '', destination_number = ''):
    self.send_message(
      'Event: Newchannel',
      'Privilege: call,all',
      'Channel: %s' % str(channel_name),
      'ChannelState: %d' % channel_state,
      'ChannelStateDesc: %s' % self.ASTERISK_CHANNEL_STATES[channel_state],
      'CallerIDNum: %s' % str(caller_id_number),
      'CallerIDName: %s' % str(caller_id_name),
      'AccountCode:', 
      'Exten: %s' % str(destination_number),
      'Context: default',
      'Uniqueid: %s' % str(uuid),
    )


  def send_event_newstate(self, uuid, channel_name, channel_state, caller_id_number = '', caller_id_name = ''):
    self.send_message(
      'Event: Newstate',
      'Privilege: call,all',
      'Channel: %s' % str(channel_name),
      'ChannelState: %d' % channel_state,
      'ChannelStateDesc: %s' % self.ASTERISK_CHANNEL_STATES[channel_state],
      'CallerIDNum: %s' % str(caller_id_number),
      'CallerIDName: %s' % str(caller_id_name),
      'Uniqueid: %s' % str(uuid),
    )


  def send_event_newcallerid(self, uuid, channel_name, caller_id_number = '', caller_id_name = '', calling_pres = 0):

    presentation = self.ASTERISK_PRESENTATION_INDICATOR[calling_pres >> 6]
    screening = self.ASTERISK_SCREENING_INDICATOR[calling_pres & 3]

    self.send_message(
      'Event: NewCallerid',
      'Privilege: call,all',
      'Channel: %s' % str(channel_name),
      'CallerIDNum: %s' % str(caller_id_number),
      'CallerIDName: %s' % str(caller_id_name),
      'Uniqueid: %s' % str(uuid),
      'CID-CallingPres: %d (%s, %s)' % (calling_pres, presentation, screening),
    )


  def send_event_hangup(self, uuid, channel_name, caller_id_number = '', caller_id_name = '', cause = 0):
    self.send_message(
      'Event: Hangup',
      'Privilege: call,all',
      'Channel: %s' % str(channel_name),
      'CallerIDNum: %s' % str(caller_id_number),
      'CallerIDName: %s' % str(caller_id_name),
      'Cause: %d' % cause,
      'Cause-txt: Unknown',
      'Uniqueid: %s' % str(uuid)
    )


  def send_event_dial_begin(self, uuid, channel_name, caller_id_number, caller_id_name, destination_channel, destination_uuid, destination_number):
    self.send_message(
      'Event: Dial',
      'Privilege: call,all',
      'SubEvent: Begin',
      "Channel: %s" % str(channel_name),
      "Destination: %s" % str(destination_channel),
      'CallerIDNum: %s' % str(caller_id_number),
      'CallerIDName: %s' % str(caller_id_name),
      'Uniqueid: %s' % str(uuid),
      'DestUniqueid: %s' % str(destination_uuid),
      'Dialstring: %s@default' % str(destination_number)
    )


  def send_event_dial_end(self, uuid, channel_name, dial_status = 'UNKNOWN'):
    self.send_message(
      'Event: Dial',
      'Privilege: call,all',
      'SubEvent: End',
      "Channel: %s" % str(channel_name),
      'Uniqueid: %s' % str(uuid),
      "DialStatus: %s" % str(dial_status),
    )

    
  def send_event_originate_response(self, uuid, channel_name, caller_id_number, caller_id_name, destination_number, action_id, reason):
    #reasons:
    #0: no such extension or number
    #1: no answer
    #4: answered
    #8: congested or not available

    if reason == 4:
      response = 'Success'
    else:
      response = 'Failure'

    self.send_message(
      'Event: OriginateResponse',
      'Privilege: call,all',
      'ActionID: %s' % str(action_id),
      'Response: %s' % response,
      'Channel: %s' % str(channel_name),
      'Context: default',
      'Exten: %s' % str(destination_number),
      'Reason: %d' % reason,
      'CallerIDNum: %s' % str(caller_id_number),
      'CallerIDName: %s' % str(caller_id_name),
      'Uniqueid: %s' % str(uuid),
    )


  def send_event_bridge(self, uuid, channel_name, caller_id, o_uuid, o_channel_name, o_caller_id):
    self.send_message(
      'Event: Bridge',
      'Privilege: call,all',
      'Bridgestate: Link',
      'Bridgetype: core',
      'Channel1: %s' % str(channel_name),
      'Channel2: %s' % str(o_channel_name),
      'Uniqueid1: %s' % str(uuid),
      'Uniqueid2: %s' % str(o_uuid),
      'CallerID1: %s' % str(caller_id),
      'CallerID2: %s' % str(o_caller_id),
    )

  def send_event_newaccountcode(self, uuid, channel_name):
    self.send_message(
      'Event: NewAccountCode',
      'Privilege: call,all',
      "Channel: %s" % str(channel_name),
      'Uniqueid: %s' % str(uuid),
      'AccountCode:',
      'OldAccountCode:',
    )
