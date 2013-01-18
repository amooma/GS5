-- Gemeinschaft 5 module: ip calculation functions
-- (c) AMOOMA GmbH 2012-2013
-- 

module(...,package.seeall)

function ipv4_to_i(ip_address_str)
  local octet4, octet3, octet2, octet1 = ip_address_str:match('(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)');
  if octet4 and octet3 and octet2 and octet1 then
    return (2^24*octet4 + 2^16*octet3 + 2^8*octet2 + octet1);
  end
end

function ipv4_to_network_netmask(ip_address_str)
  local octet4, octet3, octet2, octet1, netmask = ip_address_str:match('(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)/(%d%d?)');
  if octet4 and octet3 and octet2 and octet1 and netmask then
    return (2^24*octet4 + 2^16*octet3 + 2^8*octet2 + octet1), tonumber(netmask);
  end
end

function ipv4_network(ip_address, netmask)
  return math.floor(ip_address / 2^(32-netmask));
end

function ipv4_in_network(ip_address, network, netmask)
  return ipv4_network(ip_address, netmask) == ipv4_network(network, netmask);
end
