-- Gemeinschaft 5 module: string functions
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

function try(array, arguments)
  local result = array;
  
  arguments:gsub('([^%.]+)', function(entry)
    local success, result = pcall(function() result = (result[tonumber(entry) or entry]); end);
  end);
  
  return result;
end

-- to number
function to_n(value)
  value = tostring(value):gsub('[^%d%.%+%-]', '');
  return tonumber(value) or 0;
end

-- to integer
function to_i(value)
  return math.floor(to_n(value)); 
end

-- to string
function to_s(value)
  if value == nil then
    return '';
  end

  return tostring(value);
end

-- to boolean
function to_b(value)
  if type(value) == 'boolean' then
    return value;
  elseif tonumber(value) then
    return (tonumber(value) > 0);
  else
    return (tostring(value) == 'yes' or tostring(value) == 'true');
  end
end

-- to array
function to_a(line, separator)
  line = line or '';
  separator = separator or ';';
  local result = {}
  line:gsub('([^' .. separator .. ']+)', function(entry)
    table.insert(result, entry);
  end);

  return result;
end

-- stripped to array
function strip_to_a(line, separator)

  local result = {}
  line:gsub('([^' .. separator .. ']+)', function(entry)
    table.insert(result, (entry:gsub('^%s+', ''):gsub('%s+$', '')));
  end);

  return result;
end

-- downcase
function downcase(value)
  if value == nil then
    return '';
  end

  return tostring(value):lower();
end

-- remove special characters
function to_ascii(value)
  return (to_s(value):gsub('[^A-Za-z0-9%-%_ %(%)]', ''));
end

-- to SQL
function to_sql(value)
  if type(value) == 'boolean' then
    return tostring(value):upper();
  elseif type(value) == 'number' then
    return tostring(value);
  elseif type(value) == 'string' then
    return '"' .. value:gsub('"', '\\"'):gsub("'", "\\'") .. '"';
  else
    return 'NULL';
  end
end

-- to JSON
function to_json(value)
  if type(value) == 'boolean' then
    return tostring(value):lower();
  elseif type(value) == 'number' then
    return tostring(value);
  elseif type(value) == 'string' then
    return '"' .. value:gsub('"', '\\"'):gsub("'", "\\'") .. '"';
  else
    return 'null';
  end
end

-- remove leading/trailing whitespace
function strip(value)
  return (tostring(value):gsub('^%s+', ''):gsub('%s+$', ''));
end

-- split string
function partition(value, separator)
  value = tostring(value);
  separator = separator or ':'

  return value:match('^(.-)' ..  separator), value:match(separator .. '(.-)$');
end

-- check if value is empty string or nil
function blank(value)
  return (value == nil or to_s(value) == '');
end
