module Mlh
  # Fetches the authenticated user's MLH profile from the v4 API. Fields are
  # mapped to Forem profile attributes via Mlh::ProfileMapper by default.
  class UserProfile
    PROFILE_PATH = "/v4/users/me".freeze
    EXPAND_FIELDS = %w[address education professional_experience].freeze

    def self.call(...)
      new(...).call
    end

    # @param access_token [String] the MLH OAuth access token
    # @param mapper [#call, nil] wraps the response payload; defaults to
    #   Mlh::ProfileMapper. Pass nil to return the raw payload.
    def initialize(access_token, mapper: Mlh::ProfileMapper)
      @access_token = access_token
      @mapper = mapper
    end

    # @return [Hash, nil] mapped profile attributes, or nil on an empty response
    # @raise [ArgumentError] when there is no token to fetch with
    # @raise [Mlh::ApiClient::Error] propagated from the fetch
    def call
      payload = Mlh::ApiClient.new(@access_token).get(path)
      return if payload.blank?

      @mapper ? @mapper.call(payload) : payload
    end

    private

    def path
      expansions = EXPAND_FIELDS.map { |field| "expand[]=#{field}" }.join("&")
      [PROFILE_PATH, expansions].join("?")
    end
  end
end
