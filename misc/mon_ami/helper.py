# -*- coding: utf-8 -*-
# MonAMI Asterisk Manger Interface server
# helper functions
# (c) AMOOMA GmbH 2012-2013


def to_hash(message):
  message_hash = {}
  for line in message:
    keyword, delimeter, value = line.partition(": ")
    if (keyword):
      message_hash[keyword] = value.strip()

  return message_hash


def sval(array, key):
  try:
    return array[key]
  except:
    return None
