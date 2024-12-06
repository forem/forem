module Fog
  module AWS
    class CloudFormation < Fog::Service
      extend Fog::AWS::CredentialFetcher::ServiceMethods

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :host, :path, :port, :scheme, :persistent, :region, :use_iam_profile, :aws_session_token, :aws_credentials_expire_at, :instrumentor, :instrumentor_name, :sts_endpoint

      request_path 'fog/aws/requests/cloud_formation'
      request :cancel_update_stack
      request :continue_update_rollback
      request :create_change_set
      request :create_stack
      request :update_stack
      request :delete_change_set
      request :delete_stack
      request :describe_account_limits
      request :describe_change_set
      request :describe_stack_events
      request :describe_stack_resource
      request :describe_stack_resources
      request :describe_stacks
      request :estimate_template_cost
      request :execute_change_set
      request :get_stack_policy
      request :get_template
      request :get_template_summary
      request :set_stack_policy
      request :signal_resource
      request :validate_template
      request :list_change_sets
      request :list_stacks
      request :list_stack_resources

      class Mock
        def initialize(options={})
          Fog::Mock.not_implemented
        end
      end

      class Real
        include Fog::AWS::CredentialFetcher::ConnectionMethods
        # Initialize connection to CloudFormation
        #
        # ==== Notes
        # options parameter must include values for :aws_access_key_id and
        # :aws_secret_access_key in order to create a connection
        #
        # ==== Examples
        #   cf = CloudFormation.new(
        #    :aws_access_key_id => your_aws_access_key_id,
        #    :aws_secret_access_key => your_aws_secret_access_key
        #   )
        #
        # ==== Parameters
        # * options<~Hash> - config arguments for connection.  Defaults to {}.
        #
        # ==== Returns
        # * CloudFormation object with connection to AWS.
        def initialize(options={})

          @use_iam_profile = options[:use_iam_profile]

          @instrumentor       = options[:instrumentor]
          @instrumentor_name  = options[:instrumentor_name] || 'fog.aws.cloud_formation'
          @connection_options = options[:connection_options] || {}
          options[:region] ||= 'us-east-1'
          @region = options[:region]
          @host = options[:host] || "cloudformation.#{options[:region]}.amazonaws.com"
          @path       = options[:path]        || '/'
          @persistent = options[:persistent]  || false
          @port       = options[:port]        || 443
          @scheme     = options[:scheme]      || 'https'
          @connection = Fog::XML::Connection.new("#{@scheme}://#{@host}:#{@port}#{@path}", @persistent, @connection_options)

          setup_credentials(options)
        end

        def reload
          @connection.reset
        end

        private

        def setup_credentials(options)
          @aws_access_key_id      = options[:aws_access_key_id]
          @aws_secret_access_key  = options[:aws_secret_access_key]
          @aws_session_token      = options[:aws_session_token]
          @aws_credentials_expire_at = options[:aws_credentials_expire_at]

          @signer = Fog::AWS::SignatureV4.new( @aws_access_key_id, @aws_secret_access_key, @region, 'cloudformation')
        end

        def request(params)
          refresh_credentials_if_expired

          idempotent  = params.delete(:idempotent)
          parser      = params.delete(:parser)

          body, headers = Fog::AWS.signed_params_v4(
            params,
            { 'Content-Type' => 'application/x-www-form-urlencoded' },
            {
              :signer  => @signer,
              :aws_session_token  => @aws_session_token,
              :host               => @host,
              :path               => @path,
              :port               => @port,
              :version            => '2010-05-15',
              :method             => 'POST'
            }
          )

          if @instrumentor
            @instrumentor.instrument("#{@instrumentor_name}.request", params) do
              _request(body, headers, idempotent, parser)
            end
          else
            _request(body, headers, idempotent, parser)
          end
        end

        def _request(body, headers, idempotent, parser)
          @connection.request({
            :body       => body,
            :expects    => 200,
            :idempotent => idempotent,
            :headers    => headers,
            :method     => 'POST',
            :parser     => parser
          })
        rescue Excon::Errors::HTTPStatusError => error
          match = Fog::AWS::Errors.match_error(error)
          raise if match.empty?
          raise case match[:code]
                when 'NotFound', 'ValidationError'
                  Fog::AWS::CloudFormation::NotFound.slurp(error, match[:message])
                else
                  Fog::AWS::CloudFormation::Error.slurp(error, "#{match[:code]} => #{match[:message]}")
                end
        end
      end
    end
  end
end
