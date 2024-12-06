module Fog
  module AWS
    class Elasticache < Fog::Service
      extend Fog::AWS::CredentialFetcher::ServiceMethods

      class IdentifierTaken < Fog::Errors::Error; end
      class InvalidInstance < Fog::Errors::Error; end
      class AuthorizationAlreadyExists < Fog::Errors::Error; end

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :region, :host, :path, :port, :scheme, :persistent, :use_iam_profile, :aws_session_token, :aws_credentials_expire_at, :instrumentor, :instrumentor_name, :sts_endpoint

      request_path 'fog/aws/requests/elasticache'

      request :create_cache_cluster
      request :delete_cache_cluster
      request :describe_cache_clusters
      request :modify_cache_cluster
      request :reboot_cache_cluster

      request :create_cache_parameter_group
      request :delete_cache_parameter_group
      request :describe_cache_parameter_groups
      request :modify_cache_parameter_group
      request :reset_cache_parameter_group
      request :describe_engine_default_parameters
      request :describe_cache_parameters
      request :describe_reserved_cache_nodes

      request :create_cache_security_group
      request :delete_cache_security_group
      request :describe_cache_security_groups
      request :authorize_cache_security_group_ingress
      request :revoke_cache_security_group_ingress

      request :create_cache_subnet_group
      request :describe_cache_subnet_groups
      request :delete_cache_subnet_group

      request :describe_events

      model_path 'fog/aws/models/elasticache'
      model :cluster
      collection :clusters
      model :security_group
      collection :security_groups
      model :parameter_group
      collection :parameter_groups
      model :subnet_group
      collection :subnet_groups

      class Real
        include Fog::AWS::CredentialFetcher::ConnectionMethods
        def initialize(options={})
          @use_iam_profile = options[:use_iam_profile]

          @instrumentor       = options[:instrumentor]
          @instrumentor_name  = options[:instrumentor_name] || 'fog.aws.elasticache'
          options[:region] ||= 'us-east-1'

          @region = options[:region]
          @host = options[:host] || "elasticache.#{options[:region]}.amazonaws.com"
          @path       = options[:path]      || '/'
          @port       = options[:port]      || 443
          @scheme     = options[:scheme]    || 'https'
          @connection = Fog::XML::Connection.new(
            "#{@scheme}://#{@host}:#{@port}#{@path}", options[:persistent]
          )

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

          @signer = Fog::AWS::SignatureV4.new( @aws_access_key_id, @aws_secret_access_key, @region, 'elasticache')
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
            :version            => '2013-06-15'
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
                when 'CacheSecurityGroupNotFound', 'CacheParameterGroupNotFound', 'CacheClusterNotFound'
                  Fog::AWS::Elasticache::NotFound.slurp(error, match[:message])
                when 'CacheSecurityGroupAlreadyExists'
                  Fog::AWS::Elasticache::IdentifierTaken.slurp(error, match[:message])
                when 'InvalidParameterValue'
                  Fog::AWS::Elasticache::InvalidInstance.slurp(error, match[:message])
                else
                  Fog::AWS::Elasticache::Error.slurp(error, "#{match[:code]} => #{match[:message]}")
                end
        end
      end

      class Mock
        include Fog::AWS::CredentialFetcher::ConnectionMethods

        def self.data
          @data ||= Hash.new do |hash, region|
            hash[region] = Hash.new do |region_hash, key|
              region_hash[key] = {
                :clusters  => {}, # cache cluster data, indexed by cluster ID
                :security_groups => {}, # security groups
                :subnet_groups => {},
                :parameter_groups => {"default.memcached1.4" => { "CacheParameterGroupFamily"=>"memcached1.4",
                                                                  "Description"=>"Default parameter group for memcached1.4",
                                                                  "CacheParameterGroupName"=>"default.memcached1.4"
                                                                },
                                      "default.redis2.6" =>     {"CacheParameterGroupFamily"=>"redis2.6",
                                                                 "Description"=>"Default parameter group for redis2.6",
                                                                 "CacheParameterGroupName"=>"default.redis2.6"
                                                                }
                                      }
                                  }
            end
          end
        end

        def self.reset
          @data = nil
        end

        def initialize(options={})
          @aws_credentials_expire_at = Time::now + 20
          setup_credentials(options)
          @region = options[:region] || 'us-east-1'
          unless ['ap-south-1', 'ap-northeast-1', 'ap-northeast-2', 'ap-northeast-3', 'ap-southeast-1', 'ap-southeast-2', 
                  'eu-west-1', 'eu-west-2', 'eu-west-3', 'eu-central-1',
                  'us-east-1', 'us-east-2', 'us-west-1', 'us-west-2', 'ca-central-1',
                  'sa-east-1', 'cn-north-1', 'cn-northwest-1', 'ap-east-1', 'us-gov-west-1'].include?(@region)
            raise ArgumentError, "Unknown region: #{@region.inspect}"
          end
        end

        def region_data
          self.class.data[@region]
        end

        def data
          self.region_data[@aws_access_key_id]
        end

        def reset_data
          self.region_data.delete(@aws_access_key_id)
        end

        def setup_credentials(options)
          @aws_access_key_id = options[:aws_access_key_id]
        end

        # returns an Array of (Mock) elasticache nodes, representated as Hashes
        def create_cache_nodes(cluster_id, num_nodes = 1, port = '11211')
          (1..num_nodes).map do |node_number|
            node_id = "%04d" % node_number
            { # each hash represents a cache cluster node
              "CacheNodeId"           => node_id,
              "Port"                  => port,
              "ParameterGroupStatus"  => "in-sync",
              "CacheNodeStatus"       => "available",
              "CacheNodeCreateTime"   => Time.now.utc.to_s,
              "Address" =>
                "#{cluster_id}.#{node_id}.use1.cache.amazonaws.com"
            }
          end
        end
      end
    end
  end
end
