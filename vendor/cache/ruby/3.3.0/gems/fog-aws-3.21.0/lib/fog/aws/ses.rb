module Fog
  module AWS
    class SES < Fog::Service
      extend Fog::AWS::CredentialFetcher::ServiceMethods

      class InvalidParameterError < Fog::Errors::Error; end
      class MessageRejected < Fog::Errors::Error; end

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :region, :host, :path, :port, :scheme, :persistent, :use_iam_profile, :aws_session_token, :aws_credentials_expire_at, :instrumentor, :instrumentor_name, :sts_endpoint

      request_path 'fog/aws/requests/ses'
      request :delete_verified_email_address
      request :verify_email_address
      request :verify_domain_identity
      request :get_send_quota
      request :get_send_statistics
      request :list_verified_email_addresses
      request :send_email
      request :send_raw_email

      class Mock
        def initialize(options={})
          Fog::Mock.not_implemented
        end
      end

      class Real
        include Fog::AWS::CredentialFetcher::ConnectionMethods
        # Initialize connection to SES
        #
        # ==== Notes
        # options parameter must include values for :aws_access_key_id and
        # :aws_secret_access_key in order to create a connection
        #
        # ==== Examples
        #   ses = SES.new(
        #    :aws_access_key_id => your_aws_access_key_id,
        #    :aws_secret_access_key => your_aws_secret_access_key
        #   )
        #
        # ==== Parameters
        # * options<~Hash> - config arguments for connection.  Defaults to {}.
        #   * region<~String> - optional region to use. For instance, 'us-east-1' and etc.
        #
        # ==== Returns
        # * SES object with connection to AWS.
        def initialize(options={})

          @use_iam_profile = options[:use_iam_profile]
          setup_credentials(options)

          @instrumentor       = options[:instrumentor]
          @instrumentor_name  = options[:instrumentor_name] || 'fog.aws.ses'
          @connection_options     = options[:connection_options] || {}
          options[:region] ||= 'us-east-1'
          @host = options[:host] || "email.#{options[:region]}.amazonaws.com"
          @path       = options[:path]        || '/'
          @persistent = options[:persistent]  || false
          @port       = options[:port]        || 443
          @scheme     = options[:scheme]      || 'https'
          @connection = Fog::XML::Connection.new("#{@scheme}://#{@host}:#{@port}#{@path}", @persistent, @connection_options)
        end

        def reload
          @connection.reset
        end

        private

        def setup_credentials(options)
          @aws_access_key_id      = options[:aws_access_key_id]
          @aws_secret_access_key  = options[:aws_secret_access_key]
          @aws_session_token     = options[:aws_session_token]
          @aws_credentials_expire_at = options[:aws_credentials_expire_at]

          @hmac = Fog::HMAC.new('sha256', @aws_secret_access_key)
        end

        def request(params)
          refresh_credentials_if_expired

          idempotent  = params.delete(:idempotent)
          parser      = params.delete(:parser)

          headers = {
            'Content-Type'  => 'application/x-www-form-urlencoded',
            'Date'          => Fog::Time.now.to_date_header,
          }
          headers['x-amz-security-token'] = @aws_session_token if @aws_session_token
          #AWS3-HTTPS AWSAccessKeyId=<Your AWS Access Key ID>, Algorithm=HmacSHA256, Signature=<Signature>
          headers['X-Amzn-Authorization'] = 'AWS3-HTTPS '
          headers['X-Amzn-Authorization'] << 'AWSAccessKeyId=' << @aws_access_key_id
          headers['X-Amzn-Authorization'] << ', Algorithm=HmacSHA256'
          headers['X-Amzn-Authorization'] << ', Signature=' << Base64.encode64(@hmac.sign(headers['Date'])).chomp!

          body = ''
          for key in params.keys.sort
            unless (value = params[key]).nil?
              body << "#{key}=#{CGI.escape(value.to_s).gsub(/\+/, '%20')}&"
            end
          end
          body.chop! # remove trailing '&'

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
            :host       => @host,
            :method     => 'POST',
            :parser     => parser
          })
        rescue Excon::Errors::HTTPStatusError => error
          match = Fog::AWS::Errors.match_error(error)
          raise if match.empty?
          raise case match[:code]
                when 'MessageRejected'
                  Fog::AWS::SES::MessageRejected.slurp(error, match[:message])
                when 'InvalidParameterValue'
                  Fog::AWS::SES::InvalidParameterError.slurp(error, match[:message])
                else
                  Fog::AWS::SES::Error.slurp(error, "#{match[:code]} => #{match[:message]}")
                end
        end
      end
    end
  end
end
