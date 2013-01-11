-- Gemeinschaft 5 simple xml gererator class
-- (c) AMOOMA GmbH 2013
-- 

module(...,package.seeall)

SimpleXml = {}

-- Create SimpleXml object
function SimpleXml.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.class = 'simplexml';
  return object;
end

function SimpleXml.element(self, arg)
  local xml_tag = '<' .. tostring(arg[1]);
  for key, value in pairs(arg) do
    if type(key) == 'string' then
      xml_tag = xml_tag .. ' ' ..  tostring(key) .. '="' .. tostring(value) .. '"';
    end
  end
  xml_tag = xml_tag .. '>';

  for key=2, #arg do
    xml_tag = xml_tag .. '\n' .. tostring(arg[key]) .. '\n';
  end

  return xml_tag .. '</' .. tostring(arg[1]) .. '>';
end


function SimpleXml.from_hash(self, element_name, parameter_hash, key_name, value_name)
  local params_xml = '';
  for key, value in pairs(parameter_hash) do
    local arguments = { [1] = element_name };
    if key_name and value_name then
      arguments[key_name] = key;
      arguments[value_name] = value;
    else
      arguments[key] = value;
    end
    params_xml = params_xml .. tostring(self:element(arguments)) .. '\n';
  end

  return params_xml;
end
