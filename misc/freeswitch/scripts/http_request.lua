-- Gemeinschaft 5 fire and forget http request script
-- (c) AMOOMA GmbH 2013
-- 

http = require('socket.http');
http.TIMEOUT = 10;
http.USERAGENT = 'Gemeinschaft 5';

local log_identifier = argv[1];
local url = argv[2];
local user = argv[3];
local password = argv[4];

if not log_identifier or not url then
  return;
end

-- Set logger
require 'common.log';
local log = common.log.Log:new();
log.prefix = '#R# [' .. log_identifier .. '] ';

local headers = {};

if user and password then
  mime = require('mime');
  headers.Authorization = 'Basic ' .. (mime.b64(user .. ':' .. password));
end

local success, result, response_headers = http.request{url = url, headers = headers };

if success then
  log:debug('HTTP_REQUEST - url: ', url, ', auth: ', tostring(headers.Authorization ~= nil), ', result: ', result);
else
  log:notice('HTTP_REQUEST - url: ', url, ', auth: ', tostring(headers.Authorization ~= nil), ', result: ', result);
end
