-- Gemeinschaft 5 module: array functions
-- (c) AMOOMA GmbH 2013
-- 

module(...,package.seeall)

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
    if result then
      return result;
    end
  end
end


function expand_variables(line, ...)
  local variable_sets = {...};
  return (line:gsub('{([%a%d%._]+)}', function(captured)
    return expand_variable(captured, variable_sets);
  end))
end
