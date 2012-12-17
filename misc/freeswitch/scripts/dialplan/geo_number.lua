-- Gemeinschaft 5 module: geonumber class
-- (c) AMOOMA GmbH 2012
-- 

module(...,package.seeall)

GeoNumber = {}

-- create phone_book object
function GeoNumber.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.class = 'geonumber';
  self.log = arg.log;
  self.database = arg.database;
  return object;
end

function GeoNumber.country(self, phone_number)
  if phone_number:match('^%+1') then
    return { id = 0, name = 'NANP', country_code = '1' }
  end

  local country_codes = {};
  for i = 2, 4, 1 do
    table.insert(country_codes, phone_number:sub(2, i));
  end

  local sql_query = 'SELECT * FROM `countries` WHERE `country_code` IN ("' .. table.concat(country_codes, '","') .. '") ORDER BY LENGTH(`country_code`) DESC LIMIT 1';

  local country = nil;
  self.database:query(sql_query, function(entry)
    country = entry;
  end)

  return country;
end


function GeoNumber.area_code(self, phone_number, country_code)
  local sql_query = nil;
  local area_code = nil;

  if country_code == '1' then
    area_code = {}
    area_code.area_code, area_code.central_office_code, area_code.subscriber_number, area_code.extension = phone_number:match('%+1(%d%d%d)(%d%d%d)(%d%d%d%d)(%d*)');
    sql_query = 'SELECT `a`.`name`, `b`.`name` AS `country` FROM `area_codes` `a` \
      JOIN `countries` `b` ON `a`.`country_id` = `b`.`id` \
      WHERE `b`.`country_code` = "' .. tostring(country_code) .. '"\
      AND `a`.`area_code` = "' .. tostring(area_code.area_code) .. '" \
      AND `a`.`central_office_code` = "' .. tostring(area_code.central_office_code) .. '" LIMIT 1';
  else
    local  offset = #country_code;
    area_codes = {};
    for i = (3 + offset), (6 + offset), 1 do
      table.insert(area_codes, phone_number:sub((2 + offset), i));
    end

    sql_query = 'SELECT `a`.`name`, `b`.`name` AS `country` FROM `area_codes` `a` \
      JOIN `countries` `b` ON `a`.`country_id` = `b`.`id` \
      WHERE `b`.`country_code` = "' .. country_code .. '"\
      AND `a`.`area_code` IN ("' .. table.concat(area_codes, '","') .. '") ORDER BY LENGTH(`a`.`area_code`) DESC LIMIT 1';
  end

  self.database:query(sql_query, function(entry)
    area_code = entry;
  end)

  return area_code;
end


function GeoNumber.find(self, phone_number)
  if not phone_number:match('^%+%d+') then
    return nil;
  end

  local country = self:country(phone_number);
  if country then
    local area_code = self:area_code(phone_number, country.country_code);
    if area_code then
      return area_code;
    else
      return { country = country.name };
    end
  end
end
