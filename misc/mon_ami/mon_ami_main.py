# -*- coding: utf-8 -*-
# MonAMI Asterisk Manger Interface Server
# Main Programm
# (c) AMOOMA GmbH 2012-2013

from log import ldebug, linfo, lwarn, lerror, lcritic, setup_log
from time import sleep
from signal import signal, SIGHUP, SIGTERM, SIGINT
from optparse import OptionParser
from freeswitch import FreeswitchEventSocket
from mon_ami_server import MonAMIServer
from sqliter import SQLiteR

def signal_handler(signal_number, frame):
  global event_socket
  global mon_ami_server

  ldebug('signal %d received ' % signal_number, frame)

  if (signal_number == SIGTERM):
    ldebug('shutdown signal (%d) received ' % signal_number, frame)
    event_socket.stop()
    mon_ami_server.stop()
  elif (signal_number == SIGINT):
    ldebug('interrupt signal (%d) received ' % signal_number, frame)
    event_socket.stop()
    mon_ami_server.stop()
  elif (signal_number == SIGHUP):
    ldebug('hangup signal (%d) received - ignore' % signal_number, frame)

def user_password_authentication(user_name, password):
  global configuration_options

  if configuration_options.user_ignore_name and configuration_options.user_ignore_password:
    ldebug('user-password authentication credentials provided but ignored - user: %s, password: %s' % (user_name, '*' * len(str(password))))
    return True

  if configuration_options.user_override_name != None and configuration_options.user_override_password != None:
    if user_name == configuration_options.user_override_name and password == configuration_options.user_override_password:
      return True
    return False

  db = SQLiteR(configuration_options.user_db_name)
  if not db.connect():
    lerror('cound not connect to user database "%s"' % configuration_options.user_db_name)
    return False

  user = db.find(configuration_options.user_db_table, {configuration_options.user_db_name_row: user_name, configuration_options.user_db_password_row: password})
  db.disconnect()

  if user:
    ldebug('user-password authentication accepted - user: %s, password: %s' % (user_name, '*' * len(str(password))))
    return True

  linfo('user-password authentication failed - user: %s, password: %s' % (user_name, '*' * len(str(password))))
  return False

def main():
  global event_socket
  global mon_ami_server
  global configuration_options

  option_parser = OptionParser()

  # Log options
  option_parser.add_option("--log-file",  action="store", type="string", dest="log_file",  default=None)
  option_parser.add_option("--log-level", action="store", type="int",    dest="log_level", default=5)

  # FreeSWITCH event_socket
  option_parser.add_option("--freeswitch-address",  action="store", type="string", dest="freeswitch_address",  default='127.0.0.1')
  option_parser.add_option("--freeswitch-port",     action="store", type="int",    dest="freeswitch_port",     default=8021)
  option_parser.add_option("--freeswitch-password", action="store", type="string", dest="freeswitch_password", default='ClueCon')

  # Asterisk Manager Interface
  option_parser.add_option("-a", "--address", "--ami-address", action="store", type="string", dest="ami_address", default='0.0.0.0')
  option_parser.add_option("-p", "--port", "--ami-port",       action="store", type="int",    dest="ami_port",    default=5038)

  # User database
  option_parser.add_option("--user-db-name",         action="store", type="string", dest="user_db_name",         default='/opt/GS5/db/development.sqlite3')
  option_parser.add_option("--user-db-table",        action="store", type="string", dest="user_db_table",        default='sip_accounts')
  option_parser.add_option("--user-db-name-row",     action="store", type="string", dest="user_db_name_row",     default='auth_name')
  option_parser.add_option("--user-db-password-row", action="store", type="string", dest="user_db_password_row", default='password')

  # Define common User/Password options
  option_parser.add_option("--user-override-name",     action="store", type="string", dest="user_override_name",     default=None)
  option_parser.add_option("--user-override-password", action="store", type="string", dest="user_override_password", default=None)
  option_parser.add_option("--user-ignore-name",       action="store_true", dest="user_ignore_name",                 default=False)
  option_parser.add_option("--user-ignore-password",   action="store_true", dest="user_ignore_password",             default=False)

  (configuration_options, args) = option_parser.parse_args()

  setup_log(configuration_options.log_file, configuration_options.log_level)
  ldebug('starting MonAMI main process')

  # Catch signals
  signal(SIGHUP,  signal_handler)
  signal(SIGTERM, signal_handler)
  signal(SIGINT, signal_handler)

  # Starting FreeSWITCH event_socket thread
  event_socket = FreeswitchEventSocket(configuration_options.freeswitch_address, configuration_options.freeswitch_port, configuration_options.freeswitch_password)
  event_socket.start()

  if event_socket.isAlive():
    # Starting Asterisk manager thread 
    mon_ami_server = MonAMIServer(configuration_options.ami_address, configuration_options.ami_port, event_socket)
    mon_ami_server.user_password_authentication = user_password_authentication
    mon_ami_server.start()

  while mon_ami_server.isAlive():
    sleep(1)

  if event_socket.isAlive():
    ldebug('killing event_socket thread')
    event_socket.stop()

  ldebug('exiting MonAMI main process')
