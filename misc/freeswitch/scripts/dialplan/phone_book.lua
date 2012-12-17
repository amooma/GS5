-- Gemeinschaft 5 module: phone book class
-- (c) AMOOMA GmbH 2012
-- 

module(...,package.seeall)

PhoneBook = {}

-- create phone_book object
function PhoneBook.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.class = 'phonebook';
  self.log = arg.log;
  self.database = arg.database;
  return object;
end


function PhoneBook.find_entry_by_number_user_tenant(self, numbers, user_id, tenant_id)
  user_id = tonumber(user_id) or 0;
  tenant_id = tonumber(tenant_id) or 0;
  
  if not numbers or #numbers == 0 then
    return nil;
  end
  local numbers_sql = '"'  .. table.concat(numbers, '","') .. '"';

  local sql_query = 'SELECT `a`.`name` AS `number_name`, \
    `a`.`number`, \
    `b`.`id`, \
    `b`.`value_of_to_s`, \
    `b`.`phone_book_id`, \
    `b`.`image`, \
    `c`.`name` AS `phone_book_name`, \
    `d`.`bellcore_id` \
    FROM `phone_numbers` `a` \
    JOIN `phone_book_entries` `b` ON `a`.`phone_numberable_id` = `b`.`id` AND `a`.`phone_numberable_type` = "PhoneBookENtry" \
    JOIN `phone_books` `c` ON `b`.`phone_book_id` = `c`.`id` \
    LEFT JOIN `ringtones` `d` ON `a`.`id` = `d`.`ringtoneable_id` AND `d`.`ringtoneable_type` = "PhoneNumber" \
    WHERE ((`c`.`phone_bookable_type` = "User" AND `c`.`phone_bookable_id` = ' .. user_id .. ') \
    OR (`c`.`phone_bookable_type` = "Tenant" AND `c`.`phone_bookable_id` = ' .. tenant_id .. ')) \
    AND `a`.`number` IN (' .. numbers_sql .. ') \
    AND `a`.`state` = "active" \
    AND `b`.`state` = "active" \
    AND `c`.`state` = "active" \
    ORDER BY `c`.`phone_bookable_type` DESC LIMIT 1';

  local phone_book_entry = nil;

  self.database:query(sql_query, function(entry)
    phone_book_entry = entry;
    if entry.number_name then
      phone_book_entry.caller_id_name = tostring(entry.value_of_to_s) .. ' (' .. entry.number_name .. ')';
    else
      phone_book_entry.caller_id_name = entry.value_of_to_s;
    end
  end)

  return phone_book_entry;
end
