module Fog
  module AWS
    class ELB < Fog::Service
      extend Fog::AWS::CredentialFetcher::ServiceMethods

      class DuplicatePolicyName         < Fog::Errors::Error; end
      class IdentifierTaken             < Fog::Errors::Error; end
      class InvalidInstance             < Fog::Errors::Error; end
      class InvalidConfigurationRequest < Fog::Errors::Error; end
      class PolicyNotFound              < Fog::Errors::Error; end
      class PolicyTypeNotFound          < Fog::Errors::Error; end
      class Throttled                   < Fog::Errors::Error; end
      class TooManyPolicies             < Fog::Errors::Error; end
      class ValidationError             < Fog::Errors::Error; end

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :region, :host, :path, :port, :scheme, :persistent, :use_iam_profile, :aws_session_token, :aws_credentials_expire_at, :version, :instrumentor, :instrumentor_name,:sts_endpoint

      request_path 'fog/aws/requests/elb'
      request :configure_health_check
      request :create_app_cookie_stickiness_policy
      request :create_lb_cookie_stickiness_policy
      request :create_load_balancer
      request :create_load_balancer_listeners
      request :create_load_balancer_policy
      request :delete_load_balancer
      request :delete_load_balancer_listeners
      request :delete_load_balancer_policy
      request :deregister_instances_from_load_balancer
      request :describe_instance_health
      request :describe_load_balancers
      request :describe_load_balancer_attributes
      request :describe_load_balancer_policies
      request :describe_load_balancer_policy_types
      request :disable_availability_zones_for_load_balancer
      request :enable_availability_zones_for_load_balancer
      request :modify_load_balancer_attributes
      request :register_instances_with_load_balancer
      request :set_load_balancer_listener_ssl_certificate
      request :set_load_balancer_policies_of_listener
      request :attach_load_balancer_to_subnets
      request :detach_load_balancer_from_subnets
      request :apply_security_groups_to_load_balancer
      request :set_load_balancer_policies_for_backend_server
      request :add_tags
      request :describe_tags
      request :remove_tags

      model_path 'fog/aws/models/elb'
      model      :load_balancer
      collection :load_balancers
      model      :policy
      collection :policies
      model      :listener
      collection :listeners
      model      :backend_server_description
      collection :backend_server_descriptions

      class Mock
        require 'fog/aws/elb/policy_types'

        def self.data
          @data ||= Hash.new do |hash, region|
            owner_id = Fog::AWS::Mock.owner_id
            hash[region] = Hash.new do |region_hash, key|
              region_hash[key] = {
                :owner_id => owner_id,
                :load_balancers => {},
                :policy_types => Fog::AWS::ELB::Mock::POLICY_TYPES
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

          @signer = Fog::AWS::SignatureV4.new( @aws_access_key_id, @aws_secret_access_key,@region,'elasticloadbalancing')
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
        # Initialize connection to ELB
        #
        # ==== Notes
        # options parameter must include values for :aws_access_key_id and
        # :aws_secret_access_key in order to create a connection
        #
        # ==== Examples
        #   elb = ELB.new(
        #    :aws_access_key_id => your_aws_access_key_id,
        #    :aws_secret_access_key => your_aws_secret_access_key
        #   )
        #
        # ==== Parameters
        # * options<~Hash> - config arguments for connection.  Defaults to {}.
        #   * region<~String> - optional region to use. For instance, 'eu-west-1', 'us-east-1', etc.
        #
        # ==== Returns
        # * ELB object with connection to AWS.
        def initialize(options={})

          @use_iam_profile = options[:use_iam_profile]
          @connection_options     = options[:connection_options] || {}
          @instrumentor           = options[:instrumentor]
          @instrumentor_name      = options[:instrumentor_name] || 'fog.aws.elb'

          options[:region] ||= 'us-east-1'
          @region = options[:region]
          @host = options[:host] || "elasticloadbalancing.#{@region}.amazonaws.com"
          @path       = options[:path]        || '/'
          @persistent = options[:persistent]  || false
          @port       = options[:port]        || 443
          @scheme     = options[:scheme]      || 'https'
          @connection = Fog::XML::Connection.new("#{@scheme}://#{@host}:#{@port}#{@path}", @persistent, @connection_options)
          @version ||= options[:version] || '2012-06-01'

          setup_credentials(options)
        end

        attr_reader :region

        def reload
          @connection.reset
        end

        private

        def setup_credentials(options={})
          @aws_access_key_id         = options[:aws_access_key_id]
          @aws_secret_access_key     = options[:aws_secret_access_key]
          @aws_session_token         = options[:aws_session_token]
          @aws_credentials_expire_at = options[:aws_credentials_expire_at]

          @signer = Fog::AWS::SignatureV4.new(@aws_access_key_id, @aws_secret_access_key, @region, 'elasticloadbalancing')
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
                when 'CertificateNotFound'
                  Fog::AWS::IAM::NotFound.slurp(error, match[:message])
                when 'DuplicateLoadBalancerName'
                  Fog::AWS::ELB::IdentifierTaken.slurp(error, match[:message])
                when 'DuplicatePolicyName'
                  Fog::AWS::ELB::DuplicatePolicyName.slurp(error, match[:message])
                when 'InvalidInstance'
                  Fog::AWS::ELB::InvalidInstance.slurp(error, match[:message])
                when 'InvalidConfigurationRequest'
                  # when do they fucking use this shit?
                  Fog::AWS::ELB::InvalidConfigurationRequest.slurp(error, match[:message])
                when 'LoadBalancerNotFound'
                  Fog::AWS::ELB::NotFound.slurp(error, match[:message])
                when 'PolicyNotFound'
                  Fog::AWS::ELB::PolicyNotFound.slurp(error, match[:message])
                when 'PolicyTypeNotFound'
                  Fog::AWS::ELB::PolicyTypeNotFound.slurp(error, match[:message])
                when 'Throttling'
                  Fog::AWS::ELB::Throttled.slurp(error, match[:message])
                when 'TooManyPolicies'
                  Fog::AWS::ELB::TooManyPolicies.slurp(error, match[:message])
                when 'ValidationError'
                  Fog::AWS::ELB::ValidationError.slurp(error, match[:message])
                else
                  Fog::AWS::ELB::Error.slurp(error, "#{match[:code]} => #{match[:message]}")
                end
        end
      end
    end
  end
end
