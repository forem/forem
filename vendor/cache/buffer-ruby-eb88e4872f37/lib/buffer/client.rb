module Buffer
  class Client
    include Core
    include User
    include Profile
    include Update
    include Link
    include Info

    attr_accessor :access_token

    URL = 'https://api.bufferapp.com/1/'.freeze

    def initialize(access_token)
      @access_token = access_token
    end

    def connection
      @connection ||= Faraday.new(url: URL) do |faraday|
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end
    end

    def auth_query
      { access_token: @access_token }
    end
  end
end
