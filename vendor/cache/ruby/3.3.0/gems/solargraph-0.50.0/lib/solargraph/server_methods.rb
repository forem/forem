# frozen_string_literal: true

require 'socket'

module Solargraph
  module ServerMethods
    # @return [Integer]
    def available_port
      socket = Socket.new(:INET, :STREAM, 0)
      socket.bind(Addrinfo.tcp("127.0.0.1", 0))
      port = socket.local_address.ip_port
      socket.close
      port
    end
  end
end
