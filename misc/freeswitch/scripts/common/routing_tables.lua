-- Gemeinschaft 5 module: routing table functions
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

function expand_variables(line, variables_list)
  variables_list = variables_list or {};

  return (line:gsub('{([%a%d_]+)}', function(captured)
    return variables_list[captured] or '';
  end))
end


function match_route(entry, search_str, variables_list)
  if not entry or not search_str then
    return { error = 'No input values' };
  end

  local result = nil;
  local success = nil;
  success, result = pcall(string.find, search_str, entry[1]);
  
  if not success then
    return { error = result, line = line }
  elseif result then
    local route = {
      pattern = entry[1],
      value = search_str:gsub(entry[1], expand_variables(entry[#entry], variables_list)),
    }

    for index = 2, #entry-1 do
      local attribute = entry[index]:match('^(.-)%s*=');
      if attribute then
        route[attribute] = entry[index]:match('=%s*(.-)$');
      end
    end

    return route;
  end
  
  return {};
end


function match_caller_id(entry, search_str, variables_list)
  if not entry or not search_str then
    return { error = 'No input values' };
  end
  local result = nil;
  local success = nil;
  success, result = pcall(string.find, search_str, entry[1]);
  if not success then
    return { error = result, line = line }
  elseif result then
    return {
      value = search_str:gsub(entry[1], expand_variables(entry[4], variables_list)),
      class =  entry[2],
      endpoint = entry[3],
      pattern = entry[1],
    }
  end
  
  return {};
end
