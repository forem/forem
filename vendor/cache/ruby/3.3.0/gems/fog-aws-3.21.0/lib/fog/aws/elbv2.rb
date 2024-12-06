module Fog
  module AWS
    class ELBV2 < ELB
      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :region, :host, :path, :port, :scheme, :persistent, :use_iam_profile, :aws_session_token, :aws_credentials_expire_at, :version, :instrumentor, :instrumentor_name,:sts_endpoint

      request_path 'fog/aws/requests/elbv2'
      request :add_tags
      request :create_load_balancer
      request :describe_tags
      request :remove_tags
      request :describe_load_balancers
      request :describe_listeners

      class Real < ELB::Real
        def initialize(options={})
          @version = '2015-12-01'

          super(options)
        end
      end

      class Mock
        def self.data
          @data ||= Hash.new do |hash, region|
            owner_id = Fog::AWS::Mock.owner_id
            hash[region] = Hash.new do |region_hash, key|
              region_hash[key] = {
                :owner_id => owner_id,
                :load_balancers_v2 => {}
              }
            end
          end
        end

        def self.dns_name(name, region)
          "#{name}-#{Fog::Mock.random_hex(8)}.#{region}.elb.amazonaws.com"
        end

        def self.reset
          @data = nil
        end

        attr_reader :region

        def initialize(options={})
          @use_iam_profile = options[:use_iam_profile]

          @region = options[:region] || 'us-east-1'
          setup_credentials(options)

          Fog::AWS.validate_region!(@region)
        end

        def setup_credentials(options)
          @aws_access_key_id     = options[:aws_access_key_id]
          @aws_secret_access_key = options[:aws_secret_access_key]

          @signer = Fog::AWS::SignatureV4.new(@aws_access_key_id, @aws_secret_access_key,@region,'elasticloadbalancing')
        end

        def data
          self.class.data[@region][@aws_access_key_id]
        end

        def reset_data
          self.class.data[@region].delete(@aws_access_key_id)
        end
      end
    end
  end
end
