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
  self.ignore_on_update = arg.ignore_on_update or {};
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


function Database.insert_or_update(self, db_table, record, use_on_update)
  ignore_on_update =  ignore_on_update or self.ignore_on_update;
  local record_sql_create = {};
  local record_sql_update = {};

  for key, value in pairs(record) do
    if ignore_on_update[key] ~= false then
      table.insert(record_sql_update, self:key_value(key, value));
    end
    table.insert(record_sql_create, self:key_value(key, value));
  end

  local sql_query = 'INSERT INTO `' .. db_table .. '` SET ' .. table.concat(record_sql_create, ', ') .. ' ON DUPLICATE KEY UPDATE ' .. table.concat(record_sql_update, ', ');

  return self:query(sql_query);
end


function Database.key_value(self, key, value)
  return self:escape(key, '`') .. ' = ' .. self:escape(value, '"');
end


function Database.escape(self, value, str_quotes)
  str_quotes = str_quotes or '';
  if type(value) == 'boolean' then
    return tostring(value):upper();
  elseif type(value) == 'number' then
    return tostring(value);
  elseif type(value) == 'string' then
    return str_quotes .. value:gsub('"', '\\"'):gsub("'", "\\'") .. str_quotes;
  elseif type(value) == 'table' and value.raw then
    return tostring(value[1]);
  else
    return 'NULL';
  end
end


function Database.release(self)
  if self.conn then
    self.conn:release();
  end
end
