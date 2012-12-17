# -*- coding: utf-8 -*-
# SQLite library

import sqlite3

class SQLiteR():
  
  def __init__(self, database = None):
    self.db_name = database
    if (self.db_name == None):
      self.db_name = ':memory:'
    self.db_conn = None
    self.db_cursor = None

  def record_factory(self, cursor, row):
    record = dict() 
    for index, column in enumerate(cursor.description):
      record[column[0]] = row[index]
    return record 

  def connect(self, isolation_level = None):
    try:
      self.db_conn = sqlite3.connect(self.db_name)
      self.db_conn.row_factory = self.record_factory
      self.db_cursor = self.db_conn.cursor()
    except:
      return False

    self.db_conn.isolation_level = isolation_level
    return True

  def disconnect(self):
    try:
      self.db_nonn.close()
    except:
      return False
    return True

  def execute(self, query, parameters = []):
    try:
      return self.db_cursor.execute(query, parameters)
    except:
      return False

  def fetch_row(self):
    return self.db_cursor.fetchone()

  def fetch_rows(self):
    return self.db_cursor.fetchall()

  def execute_get_rows(self, query, parameters = []):
    if (self.execute(query, parameters)):
      return self.fetch_rows()
    else:
      return False

  def execute_get_row(self, query, parameters = []):
    query = "%s LIMIT 1" % query
    if (self.execute(query, parameters)):
      return self.fetch_row()
    else:
      return False

  def execute_get_value(self, query, parameters = []):
    row = self.execute_get_row(query, parameters)
    if (row):
      return row[0]
    else:
      return row

  def create_table(self, table, structure, primary_key = None):
    columns = list()
    for row in structure:
      key, value = row.items()[0]
      sql_type = "VARCHAR(255)"
      sql_key = ''
      if (key == primary_key):
        sql_key = 'PRIMARY KEY'
      type_r = value.split(':', 1)
      type_n = type_r[0]
      if (type_n == 'integer'):
        sql_type = 'INTEGER'
      elif (type_n == 'string'):
        try:
          sql_type = "VARCHAR(%s)" % type_r[1]
        except IndexError, e:
          sql_type = "VARCHAR(255)"
        
      columns.append('"%s" %s %s' % (key, sql_type, sql_key))

    query = 'CREATE TABLE "%s" (%s)' % (table, ', '.join(columns))
    return self.execute(query)

  def save(self, table, row):
    keys = row.keys()
    query = 'INSERT OR REPLACE INTO "%s" (%s) VALUES (:%s)' % (table, ', '.join(keys), ', :'.join(keys))

    return self.execute(query, row)

  def find_sql(self, table, rows = None):
    values = list()
    if (rows):
      if (type(rows) == type(list())):
        rows_list = rows
      else:
        rows_list = list()
        rows_list.append(rows) 
      
      query_parts = list()
      
      for row in rows_list:
        statements = list()        
        for key, value in row.items():
          if (value == None):
            statements.append("\"%s\" IS ?" % (key))
          else:
            statements.append("\"%s\" = ?" % (key))
          values.append(value)
        query_parts.append('(%s)' % ' AND '.join(statements))
        
      query = 'SELECT * FROM "%s" WHERE %s' % (table, ' OR '.join(query_parts))
    else:
      query = 'SELECT * FROM "%s"' % table
    return query, values
    
  def find(self, table, row = None):
    query, value = self.find_sql(table, row)
    return self.execute_get_row(query, value)

  def findall(self, table, row = None):
    query, values = self.find_sql(table, row)
    return self.execute_get_rows(query, values) 
