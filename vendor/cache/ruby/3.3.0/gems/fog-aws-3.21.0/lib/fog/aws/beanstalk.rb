module Fog
  module AWS
    class ElasticBeanstalk < Fog::Service
      extend Fog::AWS::CredentialFetcher::ServiceMethods

      class InvalidParameterError < Fog::Errors::Error; end

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :region, :host, :path, :port, :scheme, :persistent, :use_iam_profile, :aws_session_token, :aws_credentials_expire_at, :instrumentor, :instrumentor_name, :sts_endpoint

      request_path 'fog/aws/requests/beanstalk'

      request :check_dns_availability
      request :create_application
      request :create_application_version
      request :create_configuration_template
      request :create_environment
      request :create_storage_location
      request :delete_application
      request :delete_application_version
      request :delete_configuration_template
      request :delete_environment_configuration
      request :describe_applications
      request :describe_application_versions
      request :describe_configuration_options
      request :describe_configuration_settings
      request :describe_environment_resources
      request :describe_environments
      request :describe_events
      request :list_available_solution_stacks
      request :rebuild_environment
      request :request_environment_info
      request :restart_app_server
      request :retrieve_environment_info
      request :swap_environment_cnames
      request :terminate_environment
      request :update_application
      request :update_application_version
      request :update_configuration_template
      request :update_environment
      request :validate_configuration_settings

      model_path 'fog/aws/models/beanstalk'

      model       :application
      collection  :applications
      model       :environment
      collection  :environments
      model       :event
      collection  :events
      model       :template
      collection  :templates
      model       :version
      collection  :versions

      class Mock
        def initialize(options={})
          Fog::Mock.not_implemented
        end
      end

      class Real
        include Fog::AWS::CredentialFetcher::ConnectionMethods
        def initialize(options={})

          @use_iam_profile = options[:use_iam_profile]

          @connection_options = options[:connection_options] || {}
          options[:region] ||= 'us-east-1'
          @host = options[:host] || "elasticbeanstalk.#{options[:region]}.amazonaws.com"
          @path       = options[:path]        || '/'
          @persistent = options[:persistent]  || false
          @port       = options[:port]        || 443
          @scheme     = options[:scheme]      || 'https'
          @connection = Fog::XML::Connection.new("#{@scheme}://#{@host}:#{@port}#{@path}", @persistent, @connection_options)
          @instrumentor       = options[:instrumentor]
          @instrumentor_name  = options[:instrumentor_name] || 'fog.aws.beanstalk'

          @region = options[:region]
          setup_credentials(options)
        end

        def reload
          @connection.reset
        end

        # Returns an array of available solutions stack details
        def solution_stacks
          list_available_solution_stacks.body['ListAvailableSolutionStacksResult']['SolutionStackDetails']
        end

        private

        def setup_credentials(options)
          @aws_access_key_id      = options[:aws_access_key_id]
          @aws_secret_access_key  = options[:aws_secret_access_key]
          @aws_session_token      = options[:aws_session_token]
          @aws_credentials_expire_at = options[:aws_credentials_expire_at]

          @signer = Fog::AWS::SignatureV4.new( @aws_access_key_id, @aws_secret_access_key, @region, 'elasticbeanstalk')
        end

        def request(params)
          refresh_credentials_if_expired

          idempotent  = params.delete(:idempotent)
          parser      = params.delete(:parser)

          body, headers = AWS.signed_params_v4(
              params,
              { 'Content-Type' => 'application/x-www-form-urlencoded' },
              {
                  :signer             => @signer,
                  :aws_session_token  => @aws_session_token,
                  :method             => "POST",
                  :host               => @host,
                  :path               => @path,
                  :port               => @port,
                  :version            => '2010-12-01'
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
          raise if match.empty?
          raise case match[:code]
                when 'InvalidParameterValue'
                  Fog::AWS::ElasticBeanstalk::InvalidParameterError.slurp(error, match[:message])
                else
                  Fog::AWS::ElasticBeanstalk::Error.slurp(error, "#{match[:code]} => #{match[:message]}")
                end
        end
      end
    end
  end
end
