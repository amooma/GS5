-- Gemeinschaft 5 module: array functions
-- (c) AMOOMA GmbH 2013
-- 

module(...,package.seeall)

MAX_JSON_DEPTH = 100;

function try(array, arguments)
  if type(arguments) ~= 'string' or type(array) ~= 'table' then
    return nil;
  end

  local result = array;
  
  arguments:gsub('([^%.]+)', function(entry)
    local success, result = pcall(function() result = (result[tonumber(entry) or entry]); end);
  end);
  
  return result;
end


function set(array, arguments, value)
  local nop, arguments_count = arguments:gsub('%.', '');
  local structure = array;
  arguments:gsub('([^%.]+)', function(entry)
    if arguments_count <= 0 then
      structure[entry] = value;
    elseif type(structure[entry]) == 'table' then
      structure = structure[entry];
    else
      structure[entry] = {};
      structure = structure[entry];
    end
    arguments_count = arguments_count - 1;
  end);
end


function expand_variable(variable_path, variable_sets)
  for index=1, #variable_sets do
    local result = try(variable_sets[index], variable_path);
    if result ~= nil then
      return result;
    end
  end
  return nil;
end

-- replace variables in a string by array values
function expand_variables(line, ...)
  local variable_sets = {...};
  return (line:gsub('{([%a%d%._]+)}', function(captured)
    return expand_variable(captured, variable_sets);
  end))
end


-- concatenate array values
function to_s(array, separator, prefix, suffix)
  require 'common.str';

  local buffer = '';
  for key, value in pairs(array) do
    buffer = common.str.append(buffer, value, separator, prefix, suffix);
  end

  return buffer;
end

-- concatenate array keys
function keys_to_s(array, separator, prefix, suffix)
  require 'common.str';

  local buffer = '';
  for key, value in pairs(array) do
    buffer = common.str.append(buffer, key, separator, prefix, suffix);
  end

  return buffer;
end

-- convert to JSON
function to_json(array, max_depth)
  max_depth = tonumber(max_depth) or MAX_JSON_DEPTH;
  max_depth = max_depth - 1;

  if max_depth <= 0 then
    return 'null';
  end 

  require 'common.str';
  local buffer = '{';
  for key, value in pairs(array) do
    if type(value) == 'table' then
      buffer = buffer .. '"' .. key .. '":' .. to_json(value, max_depth) .. ',';
    else
      buffer = buffer .. '"' .. key .. '":' .. common.str.to_json(value) .. ',';
    end
  end
  if buffer:sub(-1) == ',' then
    buffer = buffer:sub(1, -2);
  end
  buffer = buffer .. '}';
  return buffer;
end
