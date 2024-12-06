module Fog
  module AWS
    class EMR < Fog::Service
      extend Fog::AWS::CredentialFetcher::ServiceMethods

      class IdentifierTaken < Fog::Errors::Error; end

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :region, :host, :path, :port, :scheme, :persistent, :use_iam_profile, :aws_session_token, :aws_credentials_expire_at, :instrumentor, :instrumentor_name, :sts_endpoint

      request_path 'fog/aws/requests/emr'

      request :add_instance_groups
      request :add_job_flow_steps
      request :describe_job_flows
      request :modify_instance_groups
      request :run_job_flow
      request :set_termination_protection
      request :terminate_job_flows

      # model_path 'fog/aws/models/rds'
      # model       :server
      # collection  :servers
      # model       :snapshot
      # collection  :snapshots
      # model       :parameter_group
      # collection  :parameter_groups
      #
      # model       :parameter
      # collection  :parameters
      #
      # model       :security_group
      # collection  :security_groups

      class Mock
        def initialize(options={})
          Fog::Mock.not_implemented
        end
      end

      class Real
        include Fog::AWS::CredentialFetcher::ConnectionMethods
        # Initialize connection to EMR
        #
        # ==== Notes
        # options parameter must include values for :aws_access_key_id and
        # :aws_secret_access_key in order to create a connection
        #
        # ==== Examples
        #   emr = EMR.new(
        #    :aws_access_key_id => your_aws_access_key_id,
        #    :aws_secret_access_key => your_aws_secret_access_key
        #   )
        #
        # ==== Parameters
        # * options<~Hash> - config arguments for connection.  Defaults to {}.
        #   * region<~String> - optional region to use. For instance, in 'eu-west-1', 'us-east-1' and etc.
        #
        # ==== Returns
        # * EMR object with connection to AWS.
        def initialize(options={})
          @use_iam_profile = options[:use_iam_profile]
          @connection_options     = options[:connection_options] || {}
          @instrumentor           = options[:instrumentor]
          @instrumentor_name      = options[:instrumentor_name] || 'fog.aws.emr'

          options[:region] ||= 'us-east-1'
          @host = options[:host] || "elasticmapreduce.#{options[:region]}.amazonaws.com"
          @path       = options[:path]        || '/'
          @persistent = options[:persistent]  || false
          @port       = options[:port]        || 443
          @scheme     = options[:scheme]      || 'https'
          @connection = Fog::XML::Connection.new("#{@scheme}://#{@host}:#{@port}#{@path}", @persistent, @connection_options)

          @region = options[:region]
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

          @signer = Fog::AWS::SignatureV4.new( @aws_access_key_id, @aws_secret_access_key, @region, 'elasticmapreduce')
        end

        def request(params)
          refresh_credentials_if_expired

          idempotent  = params.delete(:idempotent)
          parser      = params.delete(:parser)

          body, headers = Fog::AWS.signed_params_v4(
            params,
            { 'Content-Type' => 'application/x-www-form-urlencoded' },
            {
              :signer             => @signer,
              :aws_session_token  => @aws_session_token,
              :method             => 'POST',
              :host               => @host,
              :path               => @path,
              :port               => @port,
              :version            => '2009-03-31' #'2010-07-28'
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
            :headers    => headers,
            :idempotent => idempotent,
            :method     => 'POST',
            :parser     => parser
          })
        end

      end
    end
  end
end
