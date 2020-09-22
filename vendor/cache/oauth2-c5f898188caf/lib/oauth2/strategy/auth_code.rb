module OAuth2
  module Strategy
    # The Authorization Code Strategy
    #
    # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-15#section-4.1
    class AuthCode < Base
      # The required query parameters for the authorize URL
      #
      # @param [Hash] params additional query parameters
      def authorize_params(params = {})
        params.merge('response_type' => 'code', 'client_id' => @client.id)
      end

      # The authorization URL endpoint of the provider
      #
      # @param [Hash] params additional query parameters for the URL
      def authorize_url(params = {})
        assert_valid_params(params)
        @client.authorize_url(authorize_params.merge(params))
      end

      # Retrieve an access token given the specified validation code.
      #
      # @param [String] code The Authorization Code value
      # @param [Hash] params additional params
      # @param [Hash] opts options
      # @note that you must also provide a :redirect_uri with most OAuth 2.0 providers
      def get_token(code, params = {}, opts = {})
        params = {'grant_type' => 'authorization_code', 'code' => code}.merge(@client.redirection_params).merge(params)
        params.keys.each do |key|
          params[key.to_s] = params.delete(key) if key.is_a?(Symbol)
        end

        puts "AuthCode client fetching the token.."
        puts "PARAMS: #{params}"
        puts "-"*30
        puts "OPTS: #{opts}"
        puts "-"*30

        @client.get_token(params, opts)
      end

    private

      def assert_valid_params(params)
        raise(ArgumentError, 'client_secret is not allowed in authorize URL query params') if params.key?(:client_secret) || params.key?('client_secret')
      end
    end
  end
end
