module Fog
  module AWS
    class CloudWatch < Fog::Service
      extend Fog::AWS::CredentialFetcher::ServiceMethods

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :region, :host, :path, :port, :scheme, :persistent, :use_iam_profile, :aws_session_token, :aws_credentials_expire_at, :instrumentor, :instrumentor_name, :sts_endpoint

      request_path 'fog/aws/requests/cloud_watch'

      request :list_metrics
      request :get_metric_statistics
      request :put_metric_data
      request :describe_alarms
      request :put_metric_alarm
      request :delete_alarms
      request :describe_alarm_history
      request :enable_alarm_actions
      request :disable_alarm_actions
      request :describe_alarms_for_metric
      request :set_alarm_state

      model_path 'fog/aws/models/cloud_watch'
      model       :metric
      collection  :metrics
      model       :metric_statistic
      collection  :metric_statistics
      model       :alarm_datum
      collection  :alarm_data
      model       :alarm_history
      collection  :alarm_histories
      model       :alarm
      collection  :alarms

      class Mock
        def self.data
          @data ||= Hash.new do |hash, region|
            hash[region] = Hash.new do |region_hash, key|
              region_hash[key] = {
                :metric_alarms => {}
              }
            end
          end
        end

        def self.reset
          @data = nil
        end

        def initialize(options={})
          @aws_access_key_id = options[:aws_access_key_id]

          @region = options[:region] || 'us-east-1'

          Fog::AWS.validate_region!(@region)
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
        # Initialize connection to Cloudwatch
        #
        # ==== Notes
        # options parameter must include values for :aws_access_key_id and
        # :aws_secret_access_key in order to create a connection
        #
        # ==== Examples
        #   elb = CloudWatch.new(
        #    :aws_access_key_id => your_aws_access_key_id,
        #    :aws_secret_access_key => your_aws_secret_access_key
        #   )
        #
        # ==== Parameters
        # * options<~Hash> - config arguments for connection.  Defaults to {}.
        #   * region<~String> - optional region to use. For instance, 'eu-west-1', 'us-east-1', etc.
        #
        # ==== Returns
        # * CloudWatch object with connection to AWS.
        def initialize(options={})
          @use_iam_profile = options[:use_iam_profile]

          @connection_options = options[:connection_options] || {}

          @instrumentor           = options[:instrumentor]
          @instrumentor_name      = options[:instrumentor_name] || 'fog.aws.cloud_watch'

          options[:region] ||= 'us-east-1'
          @region = options[:region]
          @host = options[:host] || "monitoring.#{options[:region]}.amazonaws.com"
          @path       = options[:path]        || '/'
          @persistent = options[:persistent]  || false
          @port       = options[:port]        || 443
          @scheme     = options[:scheme]      || 'https'
          @connection = Fog::XML::Connection.new("#{@scheme}://#{@host}:#{@port}#{@path}", @persistent, @connection_options)

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

          @signer = Fog::AWS::SignatureV4.new( @aws_access_key_id, @aws_secret_access_key,@region,'monitoring')
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
              :host               => @host,
              :path               => @path,
              :port               => @port,
              :version            => '2010-08-01',
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
        end
      end
    end
  end
end
