module Fog
  module AWS
    class DynamoDB < Fog::Service
      extend Fog::AWS::CredentialFetcher::ServiceMethods

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :aws_session_token, :host, :path, :port, :scheme, :persistent, :region, :use_iam_profile, :aws_credentials_expire_at, :instrumentor, :instrumentor_name, :sts_endpoint

      request_path 'fog/aws/requests/dynamodb'
      request :batch_get_item
      request :batch_write_item
      request :create_table
      request :delete_item
      request :delete_table
      request :describe_table
      request :get_item
      request :list_tables
      request :put_item
      request :query
      request :scan
      request :update_item
      request :update_table

      class Mock
        def self.data
          @data ||= Hash.new do |hash, key|
            hash[key] = {
              :domains => {}
            }
          end
        end

        def self.reset
          @data = nil
        end

        def initialize(options={})
          @use_iam_profile = options[:use_iam_profile]
          setup_credentials(options)
        end

        def data
          self.class.data[@aws_access_key_id]
        end

        def reset_data
          self.class.data.delete(@aws_access_key_id)
        end

        def setup_credentials(options)
          @aws_access_key_id = options[:aws_access_key_id]
        end
      end

      class Real
        include Fog::AWS::CredentialFetcher::ConnectionMethods
        # Initialize connection to DynamoDB
        #
        # ==== Notes
        # options parameter must include values for :aws_access_key_id and
        # :aws_secret_access_key in order to create a connection
        #
        # ==== Examples
        #   ddb = DynamoDB.new(
        #     :aws_access_key_id => your_aws_access_key_id,
        #     :aws_secret_access_key => your_aws_secret_access_key
        #   )
        #
        # ==== Parameters
        # * options<~Hash> - config arguments for connection.  Defaults to {}.
        #
        # ==== Returns
        # * DynamoDB object with connection to aws
        def initialize(options={})
          @use_iam_profile = options[:use_iam_profile]
          @region = options[:region] || 'us-east-1'

          setup_credentials(options)

          @connection_options     = options[:connection_options] || {}
          @instrumentor           = options[:instrumentor]
          @instrumentor_name      = options[:instrumentor_name] || 'fog.aws.dynamodb'

          @host       = options[:host]        || "dynamodb.#{@region}.amazonaws.com"
          @path       = options[:path]        || '/'
          @persistent = options[:persistent]  || false
          @port       = options[:port]        || '443'
          @scheme     = options[:scheme]      || 'https'

          @connection = Fog::XML::Connection.new("#{@scheme}://#{@host}:#{@port}#{@path}", @persistent, @connection_options)
        end

        private

        def setup_credentials(options)
          @aws_access_key_id          = options[:aws_access_key_id]
          @aws_secret_access_key      = options[:aws_secret_access_key]
          @aws_session_token          = options[:aws_session_token]
          @aws_credentials_expire_at  = options[:aws_credentials_expire_at]

          @signer = Fog::AWS::SignatureV4.new(@aws_access_key_id, @aws_secret_access_key, @region, 'dynamodb')
        end

        def reload
          @connection.reset
        end

        def request(params)
          refresh_credentials_if_expired

          # defaults for all dynamodb requests
          params.merge!({
            :expects  => 200,
            :method   => :post,
            :path     => '/'
          })

          # setup headers and sign with signature v4
          date = Fog::Time.now
          params[:headers] = {
            'Content-Type'  => 'application/x-amz-json-1.0',
            'Date'          => date.to_iso8601_basic,
            'Host'          => @host,
          }.merge!(params[:headers])
          params[:headers]['x-amz-security-token'] = @aws_session_token if @aws_session_token
          params[:headers]['Authorization'] = @signer.sign(params, date)

          if @instrumentor
            @instrumentor.instrument("#{@instrumentor_name}.request", params) do
              _request(params)
            end
          else
            _request(params)
          end
        end

        def _request(params)
          response = @connection.request(params)

          unless response.body.empty?
            response.body = Fog::JSON.decode(response.body)
          end

          response
        end

      end
    end
  end
end
