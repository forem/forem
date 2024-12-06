module Fog
  module AWS
    class KMS < Fog::Service
      extend Fog::AWS::CredentialFetcher::ServiceMethods

      DependencyTimeoutException       = Class.new(Fog::Errors::Error)
      DisabledException                = Class.new(Fog::Errors::Error)
      InvalidArnException              = Class.new(Fog::Errors::Error)
      InvalidGrantTokenException       = Class.new(Fog::Errors::Error)
      InvalidKeyUsageException         = Class.new(Fog::Errors::Error)
      KMSInternalException             = Class.new(Fog::Errors::Error)
      KeyUnavailableException          = Class.new(Fog::Errors::Error)
      MalformedPolicyDocumentException = Class.new(Fog::Errors::Error)
      NotFoundException                = Class.new(Fog::Errors::Error)

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :region, :host, :path, :port, :scheme, :persistent, :use_iam_profile, :aws_session_token, :instrumentor, :instrumentor_name, :aws_credentials_expire_at, :sts_endpoint

      request_path 'fog/aws/requests/kms'
      request :list_keys
      request :create_key
      request :describe_key

      model_path 'fog/aws/models/kms'
      model      :key
      collection :keys

      class Mock
        def self.data
          @data ||= Hash.new do |hash, region|
            hash[region] = Hash.new do |region_hash, access_key|
              region_hash[access_key] = {
                :keys => {},
              }
            end
          end
        end

        def self.reset
          data.clear
        end

        attr_reader :account_id

        def initialize(options={})
          @use_iam_profile = options[:use_iam_profile]
          @account_id = Fog::AWS::Mock.owner_id

          @region = options[:region] || 'us-east-1'
          setup_credentials(options)

          Fog::AWS.validate_region!(@region)
        end

        def setup_credentials(options)
          @aws_access_key_id     = options[:aws_access_key_id]
          @aws_secret_access_key = options[:aws_secret_access_key]

          @signer = Fog::AWS::SignatureV4.new(@aws_access_key_id, @aws_secret_access_key, @region, 'kms')
        end

        def data
          self.class.data[@region][@aws_access_key_id]
        end

        def reset_data
          self.class.data[@region].delete(@aws_access_key_id)
        end
      end

      class Real
        include Fog::AWS::CredentialFetcher::ConnectionMethods
        # Initialize connection to KMS
        #
        # ==== Notes
        # options parameter must include values for :aws_access_key_id and
        # :aws_secret_access_key in order to create a connection
        #
        # ==== Examples
        #   kms = KMS.new(
        #    :aws_access_key_id     => your_aws_access_key_id,
        #    :aws_secret_access_key => your_aws_secret_access_key
        #   )
        #
        # ==== Parameters
        # * options<~Hash> - config arguments for connection.  Defaults to {}.
        #   * region<~String> - optional region to use. For instance, 'eu-west-1', 'us-east-1', etc.
        #
        # ==== Returns
        # * KMS object with connection to AWS.
        def initialize(options={})

          @use_iam_profile    = options[:use_iam_profile]
          @connection_options = options[:connection_options] || {}
          @instrumentor       = options[:instrumentor]
          @instrumentor_name  = options[:instrumentor_name] || 'fog.aws.kms'

          options[:region] ||= 'us-east-1'

          @region     = options[:region]
          @host       = options[:host]       || "kms.#{@region}.amazonaws.com"
          @path       = options[:path]       || '/'
          @persistent = options[:persistent] || false
          @port       = options[:port]       || 443
          @scheme     = options[:scheme]     || 'https'

          @connection = Fog::XML::Connection.new("#{@scheme}://#{@host}:#{@port}#{@path}", @persistent, @connection_options)

          setup_credentials(options)
        end

        def reload
          @connection.reset
        end

        private

        def setup_credentials(options={})
          @aws_access_key_id         = options[:aws_access_key_id]
          @aws_secret_access_key     = options[:aws_secret_access_key]
          @aws_session_token         = options[:aws_session_token]

          @signer = Fog::AWS::SignatureV4.new(@aws_access_key_id, @aws_secret_access_key, @region, 'kms')
        end

        def request(params)
          refresh_credentials_if_expired

          idempotent  = params.delete(:idempotent)
          parser      = params.delete(:parser)

          body, headers = Fog::AWS.signed_params_v4(
            params,
            { 'Content-Type' => 'application/x-www-form-urlencoded' },
            {
              :aws_session_token  => @aws_session_token,
              :signer             => @signer,
              :host               => @host,
              :path               => @path,
              :port               => @port,
              :version            => '2014-11-01',
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
            :headers    => headers,
            :idempotent => idempotent,
            :method     => 'POST',
            :parser     => parser
          })
        rescue Excon::Errors::HTTPStatusError => error
          match = Fog::AWS::Errors.match_error(error)

          if match.empty?
            raise
          elsif Fog::AWS::KMS.const_defined?(match[:code])
            raise Fog::AWS::KMS.const_get(match[:code]).slurp(error, match[:message])
          else
            raise Fog::AWS::KMS::Error.slurp(error, "#{match[:code]} => #{match[:message]}")
          end
        end
      end
    end
  end
end
