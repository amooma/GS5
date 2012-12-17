require 'socket'
require 'timeout'

module Connectivity
	
	def self.port_open?( ip_addr, port )
		begin
			Timeout::timeout(5) {
				s = TCPSocket.new( ip_addr, port )
				s.close
				return true
			}
		rescue Errno::ECONNREFUSED
		rescue Errno::EHOSTUNREACH
		rescue Errno::EADDRNOTAVAIL
		rescue SocketError
		rescue Timeout::Error
		end
		
		return false
	end

end
