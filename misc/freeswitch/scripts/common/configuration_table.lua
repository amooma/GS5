-- Gemeinschaft 5 module: configuration table
-- (c) AMOOMA GmbH 2013
-- 

module(...,package.seeall)

-- retrieve configuration from database
function get(database, entity, section)
  if not database or not entity then
    return {};
  end

  require 'common.str'

  local sql_query = 'SELECT * FROM `gs_parameters` WHERE `entity` = "' .. entity .. '"';
  if section then
    sql_query = sql_query .. ' AND `section` = "' .. section .. '"';
  end

  local root = {}
  local parameter_class = '';

  database:query(sql_query, function(parameters)
    if not root[parameters.section] then
      root[parameters.section] = {};
    end
    parameter_class = tostring(parameters.class_type):lower();

    if parameter_class == 'boolean' then
      root[parameters.section][parameters.name] = common.str.to_b(parameters.value);
    elseif parameter_class == 'integer' then
      root[parameters.section][parameters.name] = common.str.to_i(parameters.value);
    else
      root[parameters.section][parameters.name] = tostring(parameters.value);
    end
  end)

  if section then
    return root[section];
  end
  
  return root;
end
