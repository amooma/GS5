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
    local p_section = common.str.strip(parameters.section):lower();
    local p_class_type = common.str.strip(parameters.class_type):lower();
    local p_name = common.str.strip(parameters.name);

    if not root[p_section] then
      root[p_section] = {};
    end

    if p_class_type == 'boolean' then
      root[p_section][p_name] = common.str.to_b(parameters.value);
    elseif p_class_type == 'integer' then
      root[p_section][p_name] = common.str.to_i(parameters.value);
    else
      root[p_section][p_name] = tostring(parameters.value);
    end
  end)

  if section then
    return root[section];
  end
  
  return root;
end
