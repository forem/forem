require 'twitter/error'
require 'twitter/utils'
require 'twitter/version'

module Twitter
  class Client
    include Twitter::Utils
    attr_accessor :access_token, :access_token_secret, :consumer_key, :consumer_secret, :proxy, :timeouts, :dev_environment
    attr_writer :user_agent

    # Initializes a new Client object
    #
    # @param options [Hash]
    # @return [Twitter::Client]
    def initialize(options = {})
      options.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
      yield(self) if block_given?
    end

    # @return [Boolean]
    def user_token?
      !(blank_string?(access_token) || blank_string?(access_token_secret))
    end

    # @return [String]
    def user_agent
      @user_agent ||= "TwitterRubyGem/#{Twitter::Version}"
    end

    # @return [Hash]
    def credentials
      {
        consumer_key: consumer_key,
        consumer_secret: consumer_secret,
        token: access_token,
        token_secret: access_token_secret,
      }
    end

    # @return [Boolean]
    def credentials?
      credentials.values.none? { |v| blank_string?(v) }
    end

  private

    def blank_string?(string)
      string.respond_to?(:empty?) ? string.empty? : !string
    end
  end
end
