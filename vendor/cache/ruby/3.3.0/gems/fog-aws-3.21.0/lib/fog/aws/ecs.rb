module Fog
  module AWS
    class ECS < Fog::Service

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :region, :host, :path, :port, :scheme, :persistent, :use_iam_profile, :aws_session_token, :aws_credentials_expire_at, :version, :instrumentor, :instrumentor_name,:sts_endpoint

      request_path 'fog/aws/requests/ecs'
      request :list_clusters
      request :create_cluster
      request :delete_cluster
      request :describe_clusters

      request :list_task_definitions
      request :describe_task_definition
      request :deregister_task_definition
      request :register_task_definition
      request :list_task_definition_families

      request :list_services
      request :describe_services
      request :create_service
      request :delete_service
      request :update_service

      request :list_container_instances
      request :describe_container_instances
      request :deregister_container_instance

      request :list_tasks
      request :describe_tasks
      request :run_task
      request :start_task
      request :stop_task

      class Real
        attr_reader :region

        include Fog::AWS::CredentialFetcher::ConnectionMethods
        # Initialize connection to ECS
        #
        # ==== Notes
        # options parameter must include values for :aws_access_key_id and
        # :aws_secret_access_key in order to create a connection
        #
        # ==== Examples
        #   ecs = ECS.new(
        #    :aws_access_key_id => your_aws_access_key_id,
        #    :aws_secret_access_key => your_aws_secret_access_key
        #   )
        #
        # ==== Parameters
        # * options<~Hash> - config arguments for connection.  Defaults to {}.
        #   * region<~String> - optional region to use. For instance, 'eu-west-1', 'us-east-1' and etc.
        #
        # ==== Returns
        # * ECS object with connection to AWS.
        def initialize(options={})
          @use_iam_profile = options[:use_iam_profile]
          @instrumentor       = options[:instrumentor]
          @instrumentor_name  = options[:instrumentor_name] || 'fog.aws.ecs'
          @connection_options     = options[:connection_options] || {}

          @region     = options[:region]      || 'us-east-1'
          @host       = options[:host]        || "ecs.#{@region}.amazonaws.com"
          @path       = options[:path]        || '/'
          @persistent = options[:persistent]  || false
          @port       = options[:port]        || 443
          @scheme     = options[:scheme]      || 'https'
          @connection = Fog::XML::Connection.new("#{@scheme}://#{@host}:#{@port}#{@path}", @persistent, @connection_options)
          @version    = options[:version] || '2014-11-13'

          setup_credentials(options)
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

          @signer = Fog::AWS::SignatureV4.new( @aws_access_key_id, @aws_secret_access_key,@region,'ecs')
        end

        def request(params)
          refresh_credentials_if_expired

          idempotent  = params.delete(:idempotent)
          parser      = params.delete(:parser)

          body, headers = Fog::AWS.signed_params_v4(
            params,
            {'Content-Type' => 'application/x-www-form-urlencoded' },
            {
              :aws_session_token  => @aws_session_token,
              :signer             => @signer,
              :host               => @host,
              :path               => @path,
              :port               => @port,
              :version            => @version,
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
          raise if match.empty?
          raise case match[:code]
                when 'NotFound'
                  Fog::AWS::ECS::NotFound.slurp(error, match[:message])
                else
                  Fog::AWS::ECS::Error.slurp(error, "#{match[:code]} => #{match[:message]}")
                end
        end
      end

      class Mock
        def self.data
          @data ||= Hash.new do |hash, region|
            hash[region] = Hash.new do |region_hash, key|
              region_hash[key] = {
                :clusters => [],
                :task_definitions => [],
                :services => [],
                :container_instances => [],
                :tasks => []
              }
            end
          end
        end

        def self.reset
          @data = nil
        end

        attr_accessor :region

        def initialize(options={})
          @use_iam_profile = options[:use_iam_profile]
          @region          = options[:region] || 'us-east-1'

          Fog::AWS.validate_region!(@region)

          setup_credentials(options)
        end

        def data
          self.class.data[@region][@aws_access_key_id]
        end

        def reset_data
          self.class.data[@region].delete(@aws_access_key_id)
        end

        def setup_credentials(options)
          @aws_access_key_id = options[:aws_access_key_id]
        end
      end
    end
  end
end
