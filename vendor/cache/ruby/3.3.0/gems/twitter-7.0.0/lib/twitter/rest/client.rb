require 'twitter/client'
require 'twitter/rest/api'
require 'twitter/rest/request'
require 'twitter/rest/utils'

module Twitter
  module REST
    class Client < Twitter::Client
      include Twitter::REST::API
      attr_accessor :bearer_token

      # @return [Boolean]
      def bearer_token?
        !!bearer_token
      end

      # @return [Boolean]
      def credentials?
        super || bearer_token?
      end
    end
  end
end
