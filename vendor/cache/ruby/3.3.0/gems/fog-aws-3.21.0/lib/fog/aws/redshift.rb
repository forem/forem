module Fog
  module AWS
    class Redshift < Fog::Service
      extend Fog::AWS::CredentialFetcher::ServiceMethods

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :region, :host, :path, :port, :scheme, :persistent, :use_iam_profile, :aws_session_token, :aws_credentials_expire_at, :instrumentor, :instrumentor_name, :sts_endpoint

      request_path 'fog/aws/requests/redshift'

      request :describe_clusters
      request :describe_cluster_parameter_groups
      request :describe_cluster_parameters
      request :describe_cluster_security_groups
      request :describe_cluster_snapshots
      request :describe_cluster_subnet_groups
      request :describe_cluster_versions
      request :describe_default_cluster_parameters
      request :describe_events
      request :describe_orderable_cluster_options
      request :describe_reserved_node_offerings
      request :describe_reserved_nodes
      request :describe_resize
      request :create_cluster
      request :create_cluster_parameter_group
      request :create_cluster_security_group
      request :create_cluster_snapshot
      request :create_cluster_subnet_group
      request :modify_cluster
      request :modify_cluster_parameter_group
      request :modify_cluster_subnet_group
      request :delete_cluster
      request :delete_cluster_parameter_group
      request :delete_cluster_security_group
      request :delete_cluster_snapshot
      request :delete_cluster_subnet_group
      request :authorize_cluster_security_group_ingress
      request :authorize_snapshot_access
      request :copy_cluster_snapshot
      request :purchase_reserved_node_offering
      request :reboot_cluster
      request :reset_cluster_parameter_group
      request :restore_from_cluster_snapshot
      request :revoke_cluster_security_group_ingress
      request :revoke_snapshot_access

      class Mock
        def initialize(options={})
          Fog::Mock.not_implemented
        end
      end

      class Real
        include Fog::AWS::CredentialFetcher::ConnectionMethods
        # Initialize connection to Redshift
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
        # * Redshift object with connection to AWS.

        def initialize(options={})
          @use_iam_profile = options[:use_iam_profile]
          @region = options[:region] || 'us-east-1'
          setup_credentials(options)

          @instrumentor       = options[:instrumentor]
          @instrumentor_name  = options[:instrumentor_name] || 'fog.aws.redshift'
          @connection_options     = options[:connection_options] || {}
          @host = options[:host] || "redshift.#{@region}.amazonaws.com"
          @version = '2012-12-01'
          @path       = options[:path]        || '/'
          @persistent = options[:persistent]  || false
          @port       = options[:port]        || 443
          @scheme     = options[:scheme]      || 'https'

          @connection = Fog::XML::Connection.new("#{@scheme}://#{@host}:#{@port}#{@path}", @persistent, @connection_options)
        end

        private
        def setup_credentials(options)
          @aws_access_key_id      = options[:aws_access_key_id]
          @aws_secret_access_key  = options[:aws_secret_access_key]
          @aws_session_token      = options[:aws_session_token]
          @aws_credentials_expire_at = options[:aws_credentials_expire_at]

          @signer = Fog::AWS::SignatureV4.new( @aws_access_key_id, @aws_secret_access_key,@region,'redshift')
        end

        def request(params, &block)
          refresh_credentials_if_expired

          parser = params.delete(:parser)
          date   = Fog::Time.now
          params[:headers]['Date'] = date.to_date_header
          params[:headers]['x-amz-date'] = date.to_iso8601_basic

          params[:headers]['Host'] = @host
          params[:headers]['x-amz-redshift-version'] = @version
          params[:headers]['x-amz-security-token'] = @aws_session_token if @aws_session_token
          params[:headers]['Authorization'] = @signer.sign params, date
          params[:parser] = parser

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
      end
    end
  end
end
