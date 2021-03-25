require 'pathname'

module Buffer
  class Client
    module Core
      API_VERSION = "1"

      private

      def get(path, options = {})
        options.merge!(auth_query)
        response = connection.get do |req|
          req.url path.remove_leading_slash
          req.params = options
        end

        interpret_response(response)
      end

      def post(path, options = {})
        params = merge_auth_token_and_query(options)
        params.merge!(options)
        response = connection.post do |req|
          req.url path.remove_leading_slash
          req.headers['Content-Type'] = "application/x-www-form-urlencoded"
          req.body = options[:body]
          req.params = params
        end

        Hashie::Mash.new(JSON.parse response.body)
      end

      def merge_auth_token_and_query(options)
        if options[:query]
          auth_query.merge options[:query]
        else
          auth_query
        end
      end

      def interpret_response(response)
        if response.status == 200
          JSON.parse response.body
        else
          handle_response_code(response)
        end
      end

      def handle_response_code(response)
        error = Hashie::Mash.new(JSON.parse(response.body))
        raise Buffer::Error::APIError,
          "Buffer API Error Code: #{error.code} " +
          "HTTP Code: #{response.status}. " +
          "Description: #{error.error}"
      end
    end
  end
end

class String
  def remove_leading_slash
    gsub(/^\//, '')
  end
end
