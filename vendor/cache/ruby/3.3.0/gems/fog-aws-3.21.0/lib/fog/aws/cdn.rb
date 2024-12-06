module Fog
  module AWS
    class CDN < Fog::Service
      extend Fog::AWS::CredentialFetcher::ServiceMethods

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :host, :path, :port, :scheme, :version, :persistent, :use_iam_profile, :aws_session_token, :aws_credentials_expire_at, :instrumentor, :instrumentor_name, :region, :sts_endpoint

      model_path 'fog/aws/models/cdn'
      model       :distribution
      collection  :distributions
      model       :streaming_distribution
      collection  :streaming_distributions

      request_path 'fog/aws/requests/cdn'
      request 'delete_distribution'
      request 'delete_streaming_distribution'
      request 'get_distribution'
      request 'get_distribution_list'
      request 'get_invalidation_list'
      request 'get_invalidation'
      request 'get_streaming_distribution'
      request 'get_streaming_distribution_list'
      request 'post_distribution'
      request 'post_streaming_distribution'
      request 'post_invalidation'
      request 'put_distribution_config'
      request 'put_streaming_distribution_config'

      class Mock
        def self.data
          @data ||= Hash.new do |hash, key|
            hash[key] =  {
                :distributions => {},
                :streaming_distributions => {},
                :invalidations => {}
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

        def signature(params)
          "foo"
        end

        def setup_credentials(options={})
          @aws_access_key_id  = options[:aws_access_key_id]
        end

        def self.distribution_id
          random_id(14)
        end

        def self.generic_id
          random_id(14)
        end

        def self.domain_name
          "#{random_id(12).downcase}.cloudfront.net"
        end

        def self.random_id(length)
          Fog::Mock.random_selection("abcdefghijklmnopqrstuvwxyz0123456789", length).upcase
        end

        CDN_ERRORS = {
          :access_denies => {:code => 'AccessDenied',:msg  => 'Access denied.',:status => 403},
          :inappropriate_xml => {:code => 'InappropriateXML',:msg  => 'The XML document you provided was well-formed and valid, but not appropriate for this operation.',:status => 400},
          :internal_error => {:code => 'InternalError',:msg  => 'We encountered an internal error. Please try again.',:status => 500},
          :invalid_action => {:code => 'InvalidAction',:msg  => 'The action specified is not valid.',:status => 400},
          :invalid_argument => {:code => 'InvalidArgument',:msg  => '%s', :status => 400},
          :not_implemented => {:code => 'NotImplemented', :msg  => 'Not implemented.',:status => 501},
          :no_such_distribution => { :code => 'NoSuchDistribution', :msg => 'The specified distribution does not exist', :status => 404 },
          :no_such_streaming_distribution => { :code => 'NoSuchStreamingDistribution', :msg => 'The specified streaming distribution does not exist', :status => 404 },
          :no_such_invalidation => { :code => 'NoSuchInvalidation', :msg => 'The specified invalidation does not exist', :status => 404 },
          :cname_exists => { :code => 'CNAMEAlreadyExists', :msg => 'One or more of the CNAMEs you provided are already associated with a different distribution', :status => 409 },
          :illegal_update => { :code => 'IllegalUpdate', :msg => 'Origin and CallerReference cannot be updated.', :status => 400 },
          :invalid_if_match_version => { :code => 'InvalidIfMatchVersion', :msg => 'The If-Match version is missing or not valid for the distribution.', :status => 400},
          :distribution_not_disabled => { :code => 'DistributionNotDisabled', :msg => 'The distribution you are trying to delete has not been disabled.', :status => 409 },

        }

        def self.error(code, argument = '')
          if error = CDN_ERRORS[code]
            raise_error(error[:status], error[:code], error[:msg] % argument)
          end
        end

        def self.raise_error(status, code, message='')
          response = Excon::Response.new
          response.status = status
          response.body = <<EOF
<ErrorResponse xmlns="http://cloudfront.amazonaws.com/doc/2010-11-01/">
   <Error>
      <Type>Sender</Type>
      <Code>#{code}</Code>
      <Message>#{message}.</Message>
   </Error>
   <RequestId>#{Fog::AWS::Mock.request_id}</RequestId>
</ErrorResponse>
EOF

          raise(Excon::Errors.status_error({:expects => 201}, response))
        end
      end

      class Real
        include Fog::AWS::CredentialFetcher::ConnectionMethods
        # Initialize connection to Cloudfront
        #
        # ==== Notes
        # options parameter must include values for :aws_access_key_id and
        # :aws_secret_access_key in order to create a connection
        #
        # ==== Examples
        #   cdn = Fog::AWS::CDN.new(
        #     :aws_access_key_id => your_aws_access_key_id,
        #     :aws_secret_access_key => your_aws_secret_access_key
        #   )
        #
        # ==== Parameters
        # * options<~Hash> - config arguments for connection.  Defaults to {}.
        #
        # ==== Returns
        # * cdn object with connection to aws.
        def initialize(options={})

          @use_iam_profile = options[:use_iam_profile]
          setup_credentials(options)
          @instrumentor      = options[:instrumentor]
          @instrumentor_name = options[:instrumentor_name] || 'fog.aws.cdn'
          @connection_options = options[:connection_options] || {}
          @host       = options[:host]      || 'cloudfront.amazonaws.com'
          @path       = options[:path]      || '/'
          @persistent = options.fetch(:persistent, true)
          @port       = options[:port]      || 443
          @scheme     = options[:scheme]    || 'https'
          @version    = options[:version]  || '2010-11-01'
          @connection = Fog::XML::Connection.new("#{@scheme}://#{@host}:#{@port}#{@path}", @persistent, @connection_options)
        end

        def reload
          @connection.reset
        end

        private

        def setup_credentials(options)
          @aws_access_key_id     = options[:aws_access_key_id]
          @aws_secret_access_key = options[:aws_secret_access_key]
          @aws_session_token     = options[:aws_session_token]
          @aws_credentials_expire_at = options[:aws_credentials_expire_at]

          @hmac       = Fog::HMAC.new('sha1', @aws_secret_access_key)
        end

        def request(params, &block)
          refresh_credentials_if_expired

          params[:headers] ||= {}
          params[:headers]['Date'] = Fog::Time.now.to_date_header
          params[:headers]['x-amz-security-token'] = @aws_session_token if @aws_session_token
          params[:headers]['Authorization'] = "AWS #{@aws_access_key_id}:#{signature(params)}"
          params[:path] = "/#{@version}/#{params[:path]}"

          if @instrumentor
            @instrumentor.instrument("#{@instrumentor_name}.request", params) do
              _request(params, &block)
            end
          else
            _request(params, &block)
          end
        end

        def _request(params, &block)
          @connection.request(params, &block)
        end

        def signature(params)
          string_to_sign = params[:headers]['Date']
          signed_string = @hmac.sign(string_to_sign)
          Base64.encode64(signed_string).chomp!
        end
      end
    end
  end

  # @deprecated
  module CDN
    # @deprecated
    class AWS < Fog::AWS::CDN
      # @deprecated
      # @overrides Fog::Service.new (from the fog-core gem)
      def self.new(*)
        Fog::Logger.deprecation 'Fog::CDN::AWS is deprecated, please use Fog::AWS::CDN.'
        super
      end
    end
  end
end
