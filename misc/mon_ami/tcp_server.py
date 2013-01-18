# -*- coding: utf-8 -*-
# MonAMI Asterisk Manger Interface Server
# TCP Server
# (c) AMOOMA GmbH 2012-2013

import socket
from traceback import format_exc
from log import ldebug, linfo, lwarn, lerror, lcritic

class TCPServer():

  def __init__(self, address=None, port=None, timeout=1):
    self.SOCKET_BACKLOG = 5
    self.port = port
    self.address = address
    self.socket_timeout = timeout

  def listen(self):
    tcpsocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    tcpsocket.setsockopt( socket.SOL_SOCKET, socket.SO_REUSEADDR, 1 )

    ldebug('binding server to %s:%d, timeout: %d' % (self.address, self.port, self.socket_timeout), self)

    try:
      tcpsocket.bind((self.address, self.port))
    except ValueError as exception:
      lerror('server socket address error: %s - %s' % (exception, format_exc()), self)
      return False
    except socket.error as exception:
      lerror('server socket error (%d): %s  - %s' % (exception[0], exception[1], format_exc()), self)
      return False
    except:
      lerror('general server socket error: %s' % format_exc(), self)
      return False

    tcpsocket.listen(self.SOCKET_BACKLOG)
    tcpsocket.settimeout(self.socket_timeout)

    return tcpsocket
