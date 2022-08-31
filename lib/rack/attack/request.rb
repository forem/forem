module Rack
  class Attack
    class Request < ::Rack::Request
      def remote_ip
        @remote_ip ||= ActionDispatch::Request.new(env).remote_ip
      end
    end
  end
end
