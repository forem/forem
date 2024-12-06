module Fog
  module AWS
    class Federation < Fog::Service
      extend Fog::AWS::CredentialFetcher::ServiceMethods

      recognizes :instrumentor, :instrumentor_name

      request_path 'fog/aws/requests/federation'

      request 'get_signin_token'

      class Mock
        def self.data
          @data ||= {}
        end

        def self.reset
          @data = nil
        end

        def initialize(options={})
        end

        def data
          self.class.data
        end

        def reset_data
          self.class.reset
        end
      end

      class Real
        include Fog::AWS::CredentialFetcher::ConnectionMethods

        def initialize(options={})
          @instrumentor       = options[:instrumentor]
          @instrumentor_name  = options[:instrumentor_name]  || 'fog.aws.federation'
          @connection_options = options[:connection_options] || {}
          @host               = 'signin.aws.amazon.com'
          @path               = '/federation'
          @scheme             = 'https'
          @connection         = Excon.new("#{@scheme}://#{@host}#{@path}")
        end

        def request(action, session)
          response = @connection.get(
            :query   => "Action=#{action}&SessionType=json&Session=#{session}",
            :expects => 200
          ).body
          Fog::JSON.decode(response)
        end
      end
    end
  end
end
