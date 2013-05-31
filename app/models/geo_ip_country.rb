class GeoIpCountry < ActiveRecord::Base
  attr_accessible :country_code, :country_id, :country_name, :from, :n_from, :n_to, :to

  def self.ip_to_i(ip_address)
    octets = ip_address.split('.')
    return (octets[0].to_i * 2**24) + (octets[1].to_i * 2**16) + (octets[2].to_i * 2**8) + octets[3].to_i
  end

  def self.find_by_ip(ip_address)
    GeoIpCountry.where(GeoIpCountry.ip_to_i(ip_address).to_s + ' BETWEEN n_from AND n_to').first
  end

  def to_s
    self.country_name
  end
end
