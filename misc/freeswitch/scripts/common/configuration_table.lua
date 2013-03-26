-- Gemeinschaft 5 module: configuration table
-- (c) AMOOMA GmbH 2013
-- 

module(...,package.seeall)


function cast(variable_type, value, default)
  require 'common.str';

  if variable_type == 'boolean' then
    return common.str.to_b(value);
  elseif variable_type == 'integer' then
    if default and not tonumber(value) then
      return default;
    end
    return common.str.to_i(value);
  elseif variable_type == 'float' then
    if default and not tonumber(value) then
      return default;
    end
    return common.str.to_n(value);
  elseif variable_type == 'string' then
    if default and not value then
      return default;
    end
    return common.str.to_s(value);
  elseif variable_type == 'array' then
    if default and not value then
      return default;
    end
    return common.str.to_a(value, ',');
  end
end

-- retrieve configuration from database
function get(database, entity, section, defaults)
  if not database or not entity then
    return {};
  end

  defaults = defaults or {};

  require 'common.str'

  local sql_query = 'SELECT * FROM `gs_parameters` WHERE `entity` = "' .. entity .. '"';
  if section then
    sql_query = sql_query .. ' AND `section` = "' .. section .. '"';
  end

  local root = defaults[1] or {}
  local parameter_class = '';

  database:query(sql_query, function(parameters)
    local p_section = common.str.strip(parameters.section):lower();
    local p_class_type = common.str.strip(parameters.class_type):lower();
    local p_name = common.str.strip(parameters.name);

    if not root[p_section] then
      root[p_section] = defaults[p_section] or {};
    end

    root[p_section][p_name] = cast(p_class_type, parameters.value);
  end)

  if section then
    return root[section] or defaults[section];
  end
  
  return root;
end


function settings(database, table_name, key, value, defaults)
  local sql_query = 'SELECT * FROM ' .. database:escape(table_name, '`') .. ' WHERE ' .. database:escape(key, '`') .. ' = ' .. database:escape(value, '"');

  local settings_entries = defaults or {};
  database:query(sql_query, function(record)
    settings_entries[record.name] = cast(record.class_type:lower(), record.value, settings_entries[record.name]);
  end);

  return settings_entries;
end
