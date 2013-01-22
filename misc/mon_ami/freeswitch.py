# -*- coding: utf-8 -*-
# MonAMI Asterisk Manger Interface server
# FreeSWITCH event socket interface
# (c) AMOOMA GmbH 2012-2013

from threading import Thread, Lock
from log import ldebug, linfo, lwarn, lerror, lcritic
from collections import deque
from time import sleep, time
from random import random
from helper import to_hash
from traceback import format_exc
import socket
import sys
import hashlib


class FreeswitchEventSocket(Thread):

  def __init__(self, host, port, password):
    Thread.__init__(self)
    self.LINE_SEPARATOR = "\n"
    self.SOCKET_TIMEOUT = 1
    self.MESSAGE_PIPE_MAX_LENGTH = 128
    self.write_lock = Lock()
    self.host = host
    self.port = port
    self.password = password
    self.runthread = True
    self.fs = None
    self.client_queues = {}


  def stop(self):
    ldebug('thread stop', self)
    self.runthread = False


  def run(self):
    ldebug('starting FreeSWITCH event_socket thread', self)

    while self.runthread:
      if not self.connect():
        ldebug('could not connect to FreeSWITCH - retry', self)
        sleep(self.SOCKET_TIMEOUT)
        continue
      ldebug('opening event_socket connection', self)

      data = ''
      while self.runthread and self.fs:
        
        try:
          recv_buffer = self.fs.recv(128)
        except socket.timeout as exception:
          # Socket timeout occured
          continue
        except:
          lerror(format_exc(), self)
          self.runthread = False
          break
        
        if not recv_buffer:
          ldebug('event_socket connection lost', self)
          break

        data += recv_buffer
        messages = data.split(self.LINE_SEPARATOR * 2)
        data = messages.pop()

        for message_str in messages:
          if not message_str:
            continue
          message_body = None
          
          message = to_hash(message_str.split(self.LINE_SEPARATOR))

          if not 'Content-Type' in message:
            ldebug('message without Content-Type', self)
            continue

          if 'Content-Length' in message and int(message['Content-Length']) > 0:
            content_length = int(message['Content-Length'])
            while len(data) < int(message['Content-Length']):
              try:
                data += self.fs.recv(content_length - len(data))
              except socket.timeout as exception:
                ldebug('Socket timeout in message body', self)
                continue
              except:
                lerror(format_exc(), self)
                break
            message_body = data.strip()
            data = ''
          else:
            content_length = 0

          self.process_message(message['Content-Type'], message, content_length, message_body)


      ldebug('closing event_socket connection', self)
      if self.fs:
        self.fs.close()


  def connect(self):
    fs = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
      fs.connect((self.host, self.port))
    except:
      lerror(format_exc(), self)
      return False
    
    fs.settimeout(self.SOCKET_TIMEOUT)
    self.fs = fs
    return True


  def authenticate(self):
    ldebug('send authentication to FreeSWITCH', self)
    self.send_message("auth %s" % self.password)


  def send(self, send_buffer):
    try:
      self.write_lock.acquire()
      self.fs.send(send_buffer)
      self.write_lock.release()
      return True
    except:
      return False


  def send_message(self, *message):
    if len(message) == 1 and type(message[0]) == list:
      self.send(self.LINE_SEPARATOR.join(message[0]) + (self.LINE_SEPARATOR * 2))
    else:
      self.send(self.LINE_SEPARATOR.join(message) + (self.LINE_SEPARATOR * 2))

  
  def process_message(self, content_type, message_head, content_length, message_body):

    if content_type == 'auth/request':
      self.authenticate()
    if content_type == 'command/reply':
      if 'Reply-Text' in message_head:
        ldebug('FreeSWITCH command reply: %s' % message_head['Reply-Text'], self)
    elif content_type == 'text/event-plain':
      event = to_hash(message_body.split(self.LINE_SEPARATOR))
      
      if 'Event-Name' in event and event['Event-Name'] in self.client_queues:
        event_type = event['Event-Name']
        for entry_id, message_pipe in self.client_queues[event_type].items():
          if type(message_pipe) == deque:
            if len(message_pipe) < self.MESSAGE_PIPE_MAX_LENGTH:
              message_pipe.appendleft({'type': 'freeswitch_event', 'body': event})
            else:
              lwarn("event queue %d full" % entry_id)
          else:
            ldebug("force-deregister event queue %d for event type %s" % (entry_id, event_type), self)
            del self.client_queues[event_type][entry_id]
      
  def register_client_queue(self, queue, event_type):
    if not event_type in self.client_queues:
      self.client_queues[event_type] = {}
      self.send_message("event plain all %s" % event_type)
      ldebug("we are listening now to events of type: %s" % event_type, self)
    self.client_queues[event_type][id(queue)] = queue
    ldebug("event queue %d registered for event type: %s" % (id(queue), event_type), self)


  def deregister_client_queue(self, queue, event_type):
    ldebug("deregister event queue %d for event type %s" % (id(queue), event_type), self)
    del self.client_queues[event_type][id(queue)]

  def deregister_client_queue_all(self, queue):
    for event_type, event_queues in self.client_queues.items():
      if id(queue) in event_queues:
        ldebug("deregister event queue %d for all registered event types - event type %s" % (id(queue), event_type), self)
        del self.client_queues[event_type][id(queue)]


  def hangup(self, uuid, hangup_cause = 'NORMAL_CLEARING'):
    ldebug('hangup channel: %s' % uuid, self)
    self.send_message('SendMsg %s' % uuid, 'call-command: hangup', 'hangup-cause: %s' % hangup_cause)

    return True

  
  def originate(self, sip_account, extension, action_id = ''):
    uuid = hashlib.md5('%s%f' % (sip_account, random() * 65534)).hexdigest()
    ldebug('originate call - from: %s, to: %s, uuid: %s' % (sip_account, extension, uuid), self)
    self.send_message('bgapi originate {origination_uuid=%s,origination_action=%s,origination_caller_id_number=%s}user/%s %s' % (uuid, action_id, sip_account, sip_account, extension))
    
    return uuid
