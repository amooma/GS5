-- Gemeinschaft 5 module: configuration file
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

function ignore_comments(line)
  return line:gsub(';+([^;]*)', function(entry) 
    return '';
  end);
end

-- parse configuration
function parse(lines, filter_section_name)
  require 'common.str'
  local section = {}
  local root = { [true] = section }

  for line in lines do
    if line then
      local ignore_line = false;
      line = ignore_comments(line);

      line:gsub('^%s*%[(.-)%]%s*$', function(section_name)
        if tostring(section_name):match('%=false$') then
          section = {}
        else
          root[common.str.strip(section_name)] = {};
          section = root[common.str.strip(section_name)];
        end
        ignore_line = true;
      end);

      if not ignore_line then
        key, value = common.str.partition(line, '=');
        if value and key and not common.str.strip(key):match('%s') then
          section[common.str.strip(key)] = common.str.strip(value);
        else
          line = common.str.strip(line);
          if not common.str.blank(line) then
            if line:match(',') then
              table.insert(section, common.str.strip_to_a(line, ','));
            else
              table.insert(section, line);
            end
          end
        end
      end
    end
  end
  
  if filter_section_name == false then
    root[true] = nil;
  elseif filter_section_name then
    return root[filter_section_name];
  end

  return root;
end

-- retrieve configuration from file
function get(file_name, filter_section_name)
  local file = io.open(file_name);

  if file then
    local result = parse(file:lines(), filter_section_name);
    file:close();
    return result;
  end
end
