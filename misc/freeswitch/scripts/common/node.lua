-- CommonModule: Node
--
module(...,package.seeall)

Node = {}

-- Create Node object
function Node.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self)
  self.__index = self
  self.log = arg.log
  self.database = arg.database
  self.record = arg.record
  self.session = arg.session
  return object
end

-- Find Node account by name
function Node.find_by_id(self, node_id)
  
  if not tonumber(node_id) then
    return nil
  end

  local sql_query = 'SELECT * FROM `gs_nodes` WHERE `id`= ' .. node_id .. ' LIMIT 1';
  local record = nil

  self.database:query(sql_query, function(node_entry)
    record = node_entry
  end)

  if record then
    local node_object = Node:new(self);
    node_object.record = record
    
    return node_object
  end

  return nil
end

-- Find Node account by name
function Node.find_by_address(self, address)
  local sql_query = 'SELECT * FROM `gs_nodes` WHERE `ip_address`= "' .. tostring(address):gsub('[^A-F0-9%.%:]', '') .. '" LIMIT 1';
  local record = nil

  self.database:query(sql_query, function(node_entry)
    record = node_entry
  end)

  if record then
    local node_object = Node:new(self);
    node_object.record = record
    
    return node_object
  end

  return nil
end

-- List Nodes
function Node.all(self)
  local sql_query = 'SELECT * FROM `gs_nodes`';
  nodes = {};

  self.database:query(sql_query, function(node_entry)
    nodes[tonumber(node_entry.id)] = node_entry;
  end)

  return nodes
end