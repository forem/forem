module Fog
  module AWS
    class AutoScaling < Fog::Service
      extend Fog::AWS::CredentialFetcher::ServiceMethods

      class IdentifierTaken < Fog::Errors::Error; end
      class ResourceInUse < Fog::Errors::Error; end
      class ValidationError < Fog::Errors::Error; end

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :host, :path, :port, :scheme, :persistent, :region, :use_iam_profile, :aws_session_token, :aws_credentials_expire_at, :instrumentor, :instrumentor_name, :sts_endpoint

      request_path 'fog/aws/requests/auto_scaling'
      request :attach_load_balancers
      request :attach_load_balancer_target_groups
      request :create_auto_scaling_group
      request :create_launch_configuration
      request :create_or_update_tags
      request :delete_auto_scaling_group
      request :delete_launch_configuration
      request :delete_notification_configuration
      request :delete_policy
      request :delete_scheduled_action
      request :delete_tags
      request :describe_adjustment_types
      request :describe_auto_scaling_groups
      request :describe_auto_scaling_instances
      request :describe_auto_scaling_notification_types
      request :describe_launch_configurations
      request :describe_metric_collection_types
      request :describe_notification_configurations
      request :describe_policies
      request :describe_scaling_activities
      request :describe_scaling_process_types
      request :describe_scheduled_actions
      request :describe_tags
      request :describe_termination_policy_types
      request :detach_load_balancers
      request :detach_load_balancer_target_groups
      request :detach_instances
      request :attach_instances
      request :disable_metrics_collection
      request :enable_metrics_collection
      request :execute_policy
      request :put_notification_configuration
      request :put_scaling_policy
      request :put_scheduled_update_group_action
      request :resume_processes
      request :set_desired_capacity
      request :set_instance_health
      request :set_instance_protection
      request :suspend_processes
      request :terminate_instance_in_auto_scaling_group
      request :update_auto_scaling_group

      model_path 'fog/aws/models/auto_scaling'
      model      :activity
      collection :activities
      model      :configuration
      collection :configurations
      model      :group
      collection :groups
      model      :instance
      collection :instances
      model      :policy
      collection :policies

      ExpectedOptions = {}

      class Real
        include Fog::AWS::CredentialFetcher::ConnectionMethods

        attr_accessor :region

        # Initialize connection to AutoScaling
        #
        # ==== Notes
        # options parameter must include values for :aws_access_key_id and
        # :aws_secret_access_key in order to create a connection
        #
        # ==== Examples
        #   as = AutoScaling.new(
        #    :aws_access_key_id => your_aws_access_key_id,
        #    :aws_secret_access_key => your_aws_secret_access_key
        #   )
        #
        # ==== Parameters
        # * options<~Hash> - config arguments for connection.  Defaults to {}.
        #
        # ==== Returns
        # * AutoScaling object with connection to AWS.

        def initialize(options={})
          @use_iam_profile = options[:use_iam_profile]

          @connection_options = options[:connection_options] || {}

          @instrumentor           = options[:instrumentor]
          @instrumentor_name      = options[:instrumentor_name] || 'fog.aws.auto_scaling'

          options[:region] ||= 'us-east-1'
          @region = options[:region]

          @host = options[:host] || "autoscaling.#{options[:region]}.amazonaws.com"
          @path       = options[:path]        || '/'
          @port       = options[:port]        || 443
          @persistent = options[:persistent]  || false
          @scheme     = options[:scheme]      || 'https'
          @connection = Fog::XML::Connection.new("#{@scheme}://#{@host}:#{@port}#{@path}", @persistent, @connection_options)

          setup_credentials(options)
        end

        def reload
          @connection.reset
        end

        private

        def request(params)
          refresh_credentials_if_expired

          idempotent  = params.delete(:idempotent)
          parser      = params.delete(:parser)

          body, headers = AWS.signed_params_v4(
            params,
            { 'Content-Type' => 'application/x-www-form-urlencoded' },
            {
              :aws_session_token  => @aws_session_token,
              :method             => 'POST',
              :signer             => @signer,
              :host               => @host,
              :path               => @path,
              :port               => @port,
              :version            => '2011-01-01'
            }
          )

          if @instrumentor
            @instrumentor.instrument("#{@instrumentor_name}.request", params) do
              _request(body, headers, idempotent, parser)
            end
          else
            _request(body,  headers, idempotent, parser)
          end
        end

        def _request(body,  headers, idempotent, parser)
          begin
            @connection.request({
              :body       => body,
              :expects    => 200,
              :idempotent => idempotent,
              :headers    =>  headers,
              :method     => 'POST',
              :parser     => parser
            })
          rescue Excon::Errors::HTTPStatusError => error
            match = Fog::AWS::Errors.match_error(error)
            raise if match.empty?
            raise case match[:code]
                  when 'AlreadyExists'
                    Fog::AWS::AutoScaling::IdentifierTaken.slurp(error, match[:message])
                  when 'ResourceInUse'
                    Fog::AWS::AutoScaling::ResourceInUse.slurp(error, match[:message])
                  when 'ValidationError'
                    Fog::AWS::AutoScaling::ValidationError.slurp(error, CGI.unescapeHTML(match[:message]))
                  else
                    Fog::AWS::AutoScaling::Error.slurp(error, "#{match[:code]} => #{match[:message]}")
                  end
          end
        end

        def setup_credentials(options)
          @aws_access_key_id         = options[:aws_access_key_id]
          @aws_secret_access_key     = options[:aws_secret_access_key]
          @aws_session_token         = options[:aws_session_token]
          @aws_credentials_expire_at = options[:aws_credentials_expire_at]

          @signer = Fog::AWS::SignatureV4.new( @aws_access_key_id, @aws_secret_access_key, @region, 'autoscaling')
        end
      end

      class Mock
        include Fog::AWS::CredentialFetcher::ConnectionMethods

        attr_accessor :region

        def self.data
          @data ||= Hash.new do |hash, region|
            owner_id = Fog::AWS::Mock.owner_id
            hash[region] = Hash.new do |region_hash, key|
              region_hash[key] = {
                :adjustment_types => [
                  'ChangeInCapacity',
                  'ExactCapacity',
                  'PercentChangeInCapacity'
                ],
                :auto_scaling_groups => {},
                :scaling_policies => {},
                :health_states => [
                  'Healthy',
                  'Unhealthy'
                ],
                :launch_configurations => {},
                :metric_collection_types => {
                  :granularities => [
                    '1Minute'
                  ],
                  :metrics => [
                    'GroupMinSize',
                    'GroupMaxSize',
                    'GroupDesiredCapacity',
                    'GroupInServiceInstances',
                    'GroupPendingInstances',
                    'GroupTerminatingInstances',
                    'GroupTotalInstances'
                  ]
                },
                :notification_configurations => {},
                :notification_types => [
                  'autoscaling:EC2_INSTANCE_LAUNCH',
                  'autoscaling:EC2_INSTANCE_LAUNCH_ERROR',
                  'autoscaling:EC2_INSTANCE_TERMINATE',
                  'autoscaling:EC2_INSTANCE_TERMINATE_ERROR',
                  'autoscaling:TEST_NOTIFICATION'
                ],
                :owner_id => owner_id,
                :process_types => [
                  'AZRebalance',
                  'AddToLoadBalancer',
                  'AlarmNotification',
                  'HealthCheck',
                  'Launch',
                  'ReplaceUnhealthy',
                  'ScheduledActions',
                  'Terminate'
                ],
                :termination_policy_types => [
                  'ClosestToNextInstanceHour',
                  'Default',
                  'NewestInstance',
                  'OldestInstance',
                  'OldestLaunchConfiguration'
                ]
              }
            end
          end
        end

        def self.reset
          @data = nil
        end

        def initialize(options={})
          @use_iam_profile = options[:use_iam_profile]
          setup_credentials(options)
          @region = options[:region] || 'us-east-1'

          Fog::AWS.validate_region!(@region)
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
      end
    end
  end
end
