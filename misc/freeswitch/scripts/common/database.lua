-- Gemeinschaft 5 module: database class
-- (c) AMOOMA GmbH 2013
-- 

module(...,package.seeall)

Database = {}

DATABASE_DSN = 'gemeinschaft';

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


function Database.connect(self)
  self.dsn = DATABASE_DSN;

  require 'common.configuration_file'
  local dsn = common.configuration_file.get('/var/lib/freeswitch/.odbc.ini', self.dsn);

  self.database_name = dsn.DATABASE;
  self.user_name = dsn.USER;
  self.password = dsn.PASSWORD;
  self.host_name = dsn.HOST;

  self.conn = freeswitch.Dbh(self.dsn, self.user_name, self.password);
  self.conn_id = tostring(self.conn);

  return self;
end


function Database.connected(self)
  return self.conn:connected();
end


function Database.query(self, sql_query, call_function)
  if call_function then
    return self.conn:query(sql_query, call_function);
  else
    return self.conn:query(sql_query);
  end
end


function Database.query_return_value(self, sql_query)
  local result = nil;

  self.conn:query(sql_query, function(row)
    for key, value in pairs(row) do
      result = value;
      return result;
    end
  end)

  return result;
end


function Database.last_insert_id(self)
  return self:query_return_value('SELECT LAST_INSERT_ID()');
end


function Database.release(self)
  if self.conn then
    self.conn:release();
  end
end
