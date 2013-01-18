# -*- coding: utf-8 -*-
# Log library
# (c) AMOOMA GmbH 2012-2013

import logging

def ldebug(entry, initiator = None):
  global logger
  logger.debug('%s(%d) %s' % (type(initiator).__name__, id(initiator), entry))

def lwarn(entry, initiator = None):
  global logger
  logger.warning('%s(%d) %s' % (type(initiator).__name__, id(initiator), entry))

def lerror(entry, initiator = None):
  global logger
  logger.error('%s(%d) %s' % (type(initiator).__name__, id(initiator), entry))

def linfo(entry, initiator = None):
  global logger
  logger.info('%s(%d) %s' % (type(initiator).__name__, id(initiator), entry))

def lcritic(entry, initiator = None):
  global logger
  logger.critical('%s(%d) %s' % (type(initiator).__name__, id(initiator), entry))

def setup_log(file_name = None, loglevel = 5, logformat = None):
  from sys import stdout
  global logger

  if file_name:
    try:
      logfile = logging.FileHandler(file_name)
    except:
      logfile = logging.StreamHandler(stdout)
  else: logfile = logging.StreamHandler(stdout)

  loglevel = int(loglevel)
  
  if (loglevel == 0):
    logfile.setLevel(logging.NOTSET)
    logger.setLevel(logging.NOTSET)
  elif (loglevel == 1):
    logfile.setLevel(logging.CRITICAL)
    logger.setLevel(logging.CRITICAL)
  elif (loglevel == 2):
    logfile.setLevel(logging.ERROR)
    logger.setLevel(logging.ERROR)
  elif (loglevel == 3):
    logfile.setLevel(logging.WARNING)
    logger.setLevel(logging.WARNING)
  elif (loglevel == 4):
    logfile.setLevel(logging.INFO)
    logger.setLevel(logging.INFO)
  elif (loglevel >= 5):
    logfile.setLevel(logging.DEBUG)
    logger.setLevel(logging.DEBUG)

  if not logformat:
    logformat = '%(asctime)s-%(name)s-%(levelname)s-%(message)s'
  
  try:
    format = logging.Formatter(logformat)
    logfile.setFormatter(format)
  except:
    format = logging.Formatter('%(asctime)s-%(name)s-%(levelname)s-%(message)s')
    logfile.setFormatter(format)
    
  logger.addHandler(logfile)

logger = logging.getLogger('#')
