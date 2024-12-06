module Fog
  module AWS
    class EFS < Fog::Service
      extend Fog::AWS::CredentialFetcher::ServiceMethods

      class FileSystemInUse < Fog::Errors::Error; end
      class IncorrectFileSystemLifeCycleState < Fog::Errors::Error; end
      class InvalidSubnet < Fog::Errors::Error; end

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :region, :host, :path, :port, :scheme, :persistent, :instrumentor, :instrumentor_name

      model_path 'fog/aws/models/efs'
      request_path 'fog/aws/requests/efs'

      model :file_system
      model :mount_target

      collection :file_systems
      collection :mount_targets

      request :create_file_system
      request :create_mount_target
      request :delete_file_system
      request :delete_mount_target
      request :describe_file_systems
      request :describe_mount_target_security_groups
      request :describe_mount_targets
      request :modify_mount_target_security_groups

      class Mock
        include Fog::AWS::CredentialFetcher::ConnectionMethods

        def self.data
          @data ||= Hash.new do |hash, region|
            hash[region] = Hash.new do |region_hash, key|
              region_hash[key] = {
                :file_systems    => {},
                :mount_targets   => {},
                :security_groups => {}
              }
            end
          end
        end

        def self.reset
          @data = nil
        end

        def data
          self.class.data[@region][@aws_access_key_id]
        end

        def reset
          self.class.reset
        end

        attr_accessor :region

        def initialize(options={})
          @region                = options[:region] || "us-east-1"
          @aws_access_key_id     = options[:aws_access_key_id]
          @aws_secret_access_key = options[:aws_secret_access_key]
        end

        def mock_compute
          @mock_compute ||= Fog::AWS::Compute.new(:aws_access_key_id => @aws_access_key_id, :aws_secret_access_key => @aws_secret_access_key, :region => @region)
        end
      end

      class Real
        include Fog::AWS::CredentialFetcher::ConnectionMethods

        def initialize(options={})
          @connection_options = options[:connection_options] || {}
          @instrumentor       = options[:instrumentor]
          @instrumentor_name  = options[:instrumentor_name] || 'fog.aws.efs'

          @region     = options[:region]     || 'us-east-1'
          @host       = options[:host]       || "elasticfilesystem.#{@region}.amazonaws.com"
          @port       = options[:port]       || 443
          @scheme     = options[:scheme]     || "https"
          @persistent = options[:persistent] || false
          @connection = Fog::XML::Connection.new("#{@scheme}://#{@host}:#{@port}#{@path}", @persistent, @connection_options)
          @version    = options[:version]    || '2015-02-01'
          @path       = options[:path]       || "/#{@version}/"

          setup_credentials(options)
        end

        def reload
          @connection.reset
        end

        def setup_credentials(options)
          @aws_access_key_id         = options[:aws_access_key_id]
          @aws_secret_access_key     = options[:aws_secret_access_key]
          @aws_session_token         = options[:aws_session_token]
          @aws_credentials_expire_at = options[:aws_credentials_expire_at]

          #global services that have no region are signed with the us-east-1 region
          #the only exception is GovCloud, which requires the region to be explicitly specified as us-gov-west-1
          @signer = Fog::AWS::SignatureV4.new(@aws_access_key_id, @aws_secret_access_key, @region, 'elasticfilesystem')
        end

        def request(params)
          refresh_credentials_if_expired
          idempotent   = params.delete(:idempotent)
          parser       = params.delete(:parser)
          expects      = params.delete(:expects) || 200
          path         = @path + params.delete(:path)
          method       = params.delete(:method) || 'GET'
          request_body = Fog::JSON.encode(params)

          body, headers = Fog::AWS.signed_params_v4(
            params,
            {
              'Content-Type' => "application/x-amz-json-1.0",
            },
            {
              :host               => @host,
              :path               => path,
              :port               => @port,
              :version            => @version,
              :signer             => @signer,
              :aws_session_token  => @aws_session_token,
              :method             => method,
              :body               => request_body
            }
          )

          if @instrumentor
            @instrumentor.instrument("#{@instrumentor_name}.request", params) do
              _request(body, headers, idempotent, parser, method, path, expects)
            end
          else
            _request(body, headers, idempotent, parser, method, path, expects)
          end
        end

        def _request(body, headers, idempotent, parser, method, path, expects)
          response = @connection.request({
            :body       => body,
            :expects    => expects,
            :idempotent => idempotent,
            :headers    => headers,
            :method     => method,
            :parser     => parser,
            :path       => path
          })
          unless response.body.empty?
            response.body = Fog::JSON.decode(response.body)
          end
          response
        rescue Excon::Errors::HTTPStatusError => error
          match = Fog::AWS::Errors.match_error(error)
          raise if match.empty?
          if match[:code] == "IncorrectFileSystemLifeCycleState"
            raise Fog::AWS::EFS::IncorrectFileSystemLifeCycleState.slurp(error, match[:message])
          elsif match[:code] == 'FileSystemInUse'
            raise Fog::AWS::EFS::FileSystemInUse.slurp(error, match[:message])
          elsif match[:code].match(/(FileSystem|MountTarget)NotFound/)
            raise Fog::AWS::EFS::NotFound.slurp(error, match[:message])
          end
          raise case match[:message]
                when /invalid ((file system)|(mount target)|(security group)) id/i
                  Fog::AWS::EFS::NotFound.slurp(error, match[:message])
                when /invalid subnet id/i
                  Fog::AWS::EFS::InvalidSubnet.slurp(error, match[:message])
                else
                  Fog::AWS::EFS::Error.slurp(error, "#{match[:code]} => #{match[:message]}")
                end
        end
      end
    end
  end
end
