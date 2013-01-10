-- Gemeinschaft 5 module: database class
-- (c) AMOOMA GmbH 2012
-- 

module(...,package.seeall)

Database = {}

DATABASE_DRIVER = 'mysql'

function Database.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.class = 'database';
  self.log = arg.log;
  self.conn = nil;
  return object;
end


function Database.connect(self, database_name, user_name, password, host_name)
  local database_driver = nil;
  if not (database_name and user_name and password) then
    require 'common.configuration_file'
    local config = common.configuration_file.get('/opt/freeswitch/scripts/ini/database.ini');
    if config then
      database_driver = config[true].driver
      database_name = config[database_driver].database
      user_name = config[database_driver].user
      password = config[database_driver].password
      host_name = config[database_driver].host
    end
  end

  host_name = host_name or 'localhost';
  database_driver = database_driver or DATABASE_DRIVER;

  if database_driver == 'mysql' then
    require "luasql.mysql"
    self.env = luasql.mysql();
  elseif database_driver == 'odbc' then
    require "luasql.odbc"
    self.env = luasql.odbc();
  end

  self.conn = self.env:connect(database_name, user_name, password, host_name);
  self.conn_id = tostring(self.conn);
  self.database_name = database_name;
  self.user_name = user_name;
  self.password = password;
  self.host_name = host_name;

  -- self.log:debug('DATABASE_CONNECT - connection: ', self.conn_id, ', environment: ', self.env);

  return self;
end


function Database.reconnect(self)
  self.conn = self.env:connect(self.database_name, self.user_name, self.password, self.host_name);
  self.conn_id = tostring(self.conn);

  if self.log then
    self.log:info('DATABASE_RECONNECT - connection: ', self.conn_id, ', environment: ', self.env);
  end

  return self;
end


function Database.connected(self)
  return self.conn;
end


function Database.query(self, sql_query, call_function)
  local cursor = self.conn:execute(sql_query);

  if cursor == nil and not self.conn:execute('SELECT @@VERSION') then
    if self.log then
      self.log:error('DATABASE_QUERY - lost connection: ', self.conn_id, ', environment: ', self.env, ', query: ', sql_query);
    end
    self:reconnect();
    
    if call_function then
      cursor = self.conn:execute(sql_query);
      self.log:notice('DATABASE_QUERY - retry: ', sql_query);
    end
  end

  if cursor and call_function then
    repeat
      row = cursor:fetch({}, 'a');
      if row then
        call_function(row);
      end
    until not row;
  end

  if type(cursor) == 'userdata' then
    cursor:close();
  end

  return cursor;
end


function Database.query_return_value(self, sql_query)
  local cursor = self.conn:execute(sql_query);

  if cursor == nil and not self.conn:execute('SELECT @@VERSION') then
    if self.log then
      self.log:error('DATABASE_QUERY - lost connection: ', self.conn_id, ', environment: ', self.env, ', query: ', sql_query);
    end
    self:reconnect();
    cursor = self.conn:execute(sql_query);
    self.log:notice('DATABASE_QUERY - retry: ', sql_query);
  end

  if type(cursor) == 'userdata' then
    local row = cursor:fetch({}, 'n');
    cursor:close();
    
    if not row then
      return row;
    else
      return row[1];
    end
  end

  return cursor;
end


function Database.last_insert_id(self)
  return self:query_return_value('SELECT LAST_INSERT_ID()');
end


function Database.release(self, sql_query, call_function)
  if self.conn then
    self.conn:close();
  end
  if self.env then
    self.env:close();
  end

  -- self.log:debug('DATABASE_RELEASE - connection: ', self.conn_id, ', status: ', self.env, ', ', self.conn);
end
