# -*- coding: utf-8 -*-
# MonAMI Asterisk Manger Interface Server
# Asterisk AMI Emulator server thread
# (c) AMOOMA GmbH 2012-2013

from threading import Thread
from log import ldebug, linfo, lwarn, lerror, lcritic
from time import sleep
from traceback import format_exc
from tcp_server import TCPServer
from mon_ami_handler import MonAMIHandler
import socket

class MonAMIServer(Thread):

  def __init__(self, address=None, port=None, event_socket=None):
    Thread.__init__(self)
    self.runthread = True
    self.port = port
    self.address = address
    self.event_socket = event_socket
    self.handler_threads = {}
    self.user_password_authentication = None

  def stop(self):
    ldebug('thread stop', self)
    ldebug('client connections: %s' % len(self.handler_threads), self)
    for thread_id, handler_thread in self.handler_threads.items():
      if handler_thread.isAlive():
        handler_thread.stop()
    self.runthread = False

  def register_handler_thread(self, handler_thread):
    if handler_thread.isAlive():
      ldebug('registering handler thread %d ' % id(handler_thread), self)
      self.handler_threads[id(handler_thread)] = handler_thread
    else:
      lwarn('handler thread passed away: %d' % id(handler_thread), self)


  def deregister_handler_thread(self, handler_thread):
    if id(handler_thread) in self.handler_threads:
      ldebug('deregistering handler thread %d ' % id(handler_thread), self)
      del self.handler_threads[id(handler_thread)]
    else:
      lwarn('handler thread %d not registered' % id(handler_thread), self)


  def run(self):
    ldebug('starting MonAMI server thread', self)
    serversocket = TCPServer(self.address, self.port).listen()
    #serversocket.setblocking(0)

    if not serversocket:
      ldebug('server socket could not be bound', self)
      return 1

    while self.runthread:
      try:
        client_socket, client_address = serversocket.accept()
      except socket.timeout as exception:
          # Socket timeout occured
          continue
      except socket.error as exception:
        lerror('socket error (%s): %s - ' % (exception, format_exc()), self)
        sleep(1)
        continue
      except:
        lerror('general error: %s - ' % format_exc(), self)
        sleep(1)
        continue

      ldebug('connected to %s:%d' % client_address, self)

      client_thread = MonAMIHandler(client_socket, client_address, self.event_socket)
      client_thread.deregister_at_server = self.deregister_handler_thread
      client_thread.user_password_authentication = self.user_password_authentication
      client_thread.start()
      if client_thread.isAlive():
        self.register_handler_thread(client_thread)

      ldebug('registered handler threads: %d' % len(self.handler_threads), self)      

    ldebug('exiting MonAMI server thread', self)
    
