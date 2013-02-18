-- Gemeinschaft 5 module: fax class
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

FAX_DOCUMENTS_DIRECTORY = '/var/spool/freeswitch/'
FAX_PARALLEL_MAX = 8;
Fax = {}

-- Create Fax object
function Fax.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self)
  self.__index = self
  self.class = 'faxaccount';
  self.log = arg.log;
  self.database = arg.database;
  self.record = arg.record;
  self.fax_directory = arg.fax_directory or FAX_DOCUMENTS_DIRECTORY;
  return object;
end

-- find fax account by id
function Fax.find_by_id(self, id)
  local sql_query = 'SELECT * FROM `fax_accounts` WHERE `id` = ' .. tonumber(id) .. ' LIMIT 1';
  local fax_account = nil;

  self.database:query(sql_query, function(fax_entry)
    fax_account = Fax:new(self);
    fax_account.record = fax_entry;
    fax_account.id = tonumber(fax_entry.id);
    fax_account.uuid = fax_entry.uuid;
  end)

  return fax_account;
end


-- find fax account by uuid
function Fax.find_by_uuid(self, uuid)
  local sql_query = 'SELECT * FROM `fax_accounts` WHERE `uuid` = "' .. uuid .. '" LIMIT 1';
  local fax_account = nil;

  self.database:query(sql_query, function(fax_entry)
    fax_account = Fax:new(self);
    fax_account.record = fax_entry;
    fax_account.id = tonumber(fax_entry.id);
    fax_account.uuid = fax_entry.uuid;
  end)

  return fax_account;
end


function Fax.destination_numbers(self, id)
  local sql_query = 'SELECT `number` FROM `phone_numbers` WHERE `phone_numberable_type` = "FaxDocument" AND `phone_numberable_id` = ' .. tonumber(id);
  local destination_numbers = {}

  self.database:query(sql_query, function(fax_entry)
    table.insert(destination_numbers, fax_entry.number);
  end)

  return destination_numbers;
end

function Fax.destination_number(self, id)
  local sql_query = 'SELECT `number` FROM `phone_numbers` WHERE `phone_numberable_type` = "FaxDocument" AND `phone_numberable_id`= ' .. tonumber(id) .. ' LIMIT 1';
  local destination_number = nil;

  self.database:query(sql_query, function(fax_entry)
    destination_number = fax_entry.number;
  end)

  return destination_number;
end

-- List waiting fax documents
function Fax.queued_for_sending(self, limit)
  limit = limit or FAX_PARALLEL_MAX;
  local sql_query = 'SELECT * FROM `fax_documents` WHERE `state` IN ("queued_for_sending","unsuccessful") AND `retry_counter` > 0 ORDER BY `sent_at` ASC LIMIT ' .. limit;
  local fax_documents = {}
  self.database:query(sql_query, function(fax_entry)
    fax_entry['destination_numbers'] = Fax:destination_numbers(fax_entry.id)
    table.insert(fax_documents, fax_entry);
  end)

  return fax_documents;
end

-- Update fax document sending status
function Fax.document_update(self, id, params)
  require 'common.str'
  local params_sql = {}
  
  for name, value in pairs(params) do
    table.insert(params_sql, '`' .. name .. '`=' .. common.str.to_sql(value));
  end

  if not params['sent_at'] then
    table.insert(params_sql, '`sent_at`=NOW()');
  end

  if not params['updated_at'] then
    table.insert(params_sql, '`updated_at`=NOW()');
  end
  
  local sql_query = 'UPDATE `fax_documents` SET ' .. table.concat(params_sql, ',') .. ' WHERE `id` = ' .. tonumber(id);

  return self.database:query(sql_query);
end


function Fax.get_parameters(self, caller)
  local fax_parameters = {
    bad_rows = caller:to_i('fax_bad_rows'),
    total_pages = caller:to_i('fax_document_total_pages'),
    transferred_pages = caller:to_i('fax_document_transferred_pages'),
    ecm_requested = caller:to_b('fax_ecm_requested'),
    ecm_used = caller:to_b('fax_ecm_used'),
    filename = caller:to_s('fax_filename'),
    image_resolution = caller:to_s('fax_image_resolution'),
    image_size = caller:to_i('fax_image_size'),
    local_station_id = caller:to_s('fax_local_station_id'),
    result_code = caller:to_i('fax_result_code'),
    result_text = caller:to_s('fax_result_text'),
    remote_station_id = caller:to_s('fax_remote_station_id'),
    success = caller:to_b('fax_success'),
    transfer_rate = caller:to_i('fax_transfer_rate'),
    v17_disabled = caller:to_b('fax_v17_disabled'),
  }

  return fax_parameters;
end
  
-- Receive Fax
function Fax.receive(self, caller, file_name)
  file_name = file_name or self.fax_directory .. 'fax_in_' .. caller.uuid .. '.tiff';

  caller:set_variable('fax_ident',   self.record.station_id)
  caller:set_variable('fax_verbose', 'false')

  caller:answer();
  local start_time = os.time();
  caller:execute('rxfax', file_name);
  local record = self:get_parameters(caller);
  record.transmission_time = os.time() - start_time;
  return record;
end

-- Send Fax
function Fax.send(self, caller, file_name)
  caller:set_variable('fax_ident',   self.record.station_id)
  caller:set_variable('fax_header',  self.record.name)
  caller:set_variable('fax_verbose', 'false')
  local start_time = os.time();
  caller:execute('txfax', file_name);
  local record = self:get_parameters(caller);
  record.transmission_time = os.time() - start_time;
  return record;
end

-- find fax document by id
function Fax.find_document_by_id(self, id)
  local sql_query = 'SELECT * FROM `fax_documents` WHERE `id` = ' .. tonumber(id) .. ' LIMIT 1'
  local record = nil

  self.database:query(sql_query, function(fax_entry)
    record = fax_entry;
  end);

  return record;
end

-- save fax document to database
function Fax.insert_document(self, record)
  require 'common.str'
  local sql_query = 'INSERT INTO `fax_documents` ( \
    inbound, \
    retry_counter, \
    fax_resolution_id, \
    state, \
    transmission_time, \
    sent_at, \
    document_total_pages, \
    document_transferred_pages, \
    ecm_requested, \
    ecm_used, \
    image_resolution, \
    image_size, \
    local_station_id, \
    result_code, \
    remote_station_id, \
    success, \
    transfer_rate, \
    created_at, \
    updated_at, \
    fax_account_id, \
    caller_id_number, \
    caller_id_name, \
    tiff, \
    uuid \
    ) VALUES ( \
      true, \
      0, \
      1, \
      "received", \
      ' .. common.str.to_sql(record.transmission_time) .. ', \
      NOW(), \
      ' .. common.str.to_sql(record.total_pages) .. ', \
      ' .. common.str.to_sql(record.transferred_pages) .. ', \
      ' .. common.str.to_sql(record.ecm_requested) .. ', \
      ' .. common.str.to_sql(record.ecm_used) .. ', \
      ' .. common.str.to_sql(record.image_resolution) .. ', \
      ' .. common.str.to_sql(record.image_size) .. ', \
      ' .. common.str.to_sql(record.local_station_id) .. ', \
      ' .. common.str.to_sql(record.result_code) .. ', \
      ' .. common.str.to_sql(record.remote_station_id) .. ', \
      ' .. common.str.to_sql(record.success) .. ', \
      ' .. common.str.to_sql(record.transfer_rate) .. ', \
      NOW(), \
      NOW(), \
      ' .. common.str.to_sql(self.id) .. ', \
      ' .. common.str.to_sql(record.caller_id_number) .. ', \
      ' .. common.str.to_sql(record.caller_id_name) .. ', \
      ' .. common.str.to_sql(record.filename) .. ', \
      ' .. common.str.to_sql(record.uuid) .. ' \
    )';

  return  self.database:query(sql_query); 
end

function Fax.trigger_notification(self, fax_document_id, uuid)
  local command = 'http_request.lua ' .. uuid .. ' http://127.0.0.1/trigger/fax?fax_account_id=' .. tostring(fax_document_id);

  require 'common.fapi'
  return common.fapi.FApi:new():execute('luarun', command);
end
