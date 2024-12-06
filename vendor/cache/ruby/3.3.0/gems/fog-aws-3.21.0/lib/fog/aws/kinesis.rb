module Fog
  module AWS
    class Kinesis < Fog::Service
      extend Fog::AWS::CredentialFetcher::ServiceMethods

      class ExpiredIterator < Fog::Errors::Error; end
      class LimitExceeded < Fog::Errors::Error; end
      class ResourceInUse < Fog::Errors::Error; end
      class ResourceNotFound < Fog::Errors::Error; end
      class ExpiredIterator < Fog::Errors::Error; end
      class InvalidArgument < Fog::Errors::Error; end
      class ProvisionedThroughputExceeded < Fog::Errors::Error; end

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :region, :host, :path, :port, :scheme, :persistent, :use_iam_profile, :aws_session_token, :aws_credentials_expire_at, :instrumentor, :instrumentor_name, :sts_endpoint

      request_path 'fog/aws/requests/kinesis'

      request :add_tags_to_stream
      request :create_stream
      request :delete_stream
      request :describe_stream
      request :get_records
      request :get_shard_iterator
      request :list_streams
      request :list_tags_for_stream
      request :merge_shards
      request :put_record
      request :put_records
      request :remove_tags_from_stream
      request :split_shard

      class Real
        include Fog::AWS::CredentialFetcher::ConnectionMethods

        def initialize(options={})
          @use_iam_profile = options[:use_iam_profile]

          @connection_options = options[:connection_options] || {}

          @instrumentor           = options[:instrumentor]
          @instrumentor_name      = options[:instrumentor_name] || 'fog.aws.kinesis'

          options[:region] ||= 'us-east-1'
          @region     = options[:region]
          @host       = options[:host] || "kinesis.#{options[:region]}.amazonaws.com"
          @path       = options[:path]        || '/'
          @persistent = options[:persistent]  || true
          @port       = options[:port]        || 443
          @scheme     = options[:scheme]      || 'https'
          @connection = Fog::XML::Connection.new("#{@scheme}://#{@host}:#{@port}#{@path}", @persistent, @connection_options)
          @version    = "20131202"

          setup_credentials(options)
        end

        private

        def setup_credentials(options)
          @aws_access_key_id      = options[:aws_access_key_id]
          @aws_secret_access_key  = options[:aws_secret_access_key]
          @aws_session_token      = options[:aws_session_token]
          @aws_credentials_expire_at = options[:aws_credentials_expire_at]

          @signer = Fog::AWS::SignatureV4.new( @aws_access_key_id, @aws_secret_access_key, @region, 'kinesis')
        end

        def request(params)
          refresh_credentials_if_expired
          idempotent  = params.delete(:idempotent)
          parser      = params.delete(:parser)

          date = Fog::Time.now
          headers = {
            'X-Amz-Target' => params['X-Amz-Target'],
            'Content-Type' => 'application/x-amz-json-1.1',
            'Host'         => @host,
            'x-amz-date'   => date.to_iso8601_basic
          }
          headers['x-amz-security-token'] = @aws_session_token if @aws_session_token
          body = MultiJson.dump(params[:body])
          headers['Authorization'] = @signer.sign({:method => "POST", :headers => headers, :body => body, :query => {}, :path => @path}, date)

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
                when 'ExpiredIteratorException'
                  Fog::AWS::Kinesis::ExpiredIterator.slurp(error, match[:message])
                when 'LimitExceededException'
                  Fog::AWS::Kinesis::LimitExceeded.slurp(error, match[:message])
                when 'ResourceInUseException'
                  Fog::AWS::Kinesis::ResourceInUse.slurp(error, match[:message])
                when 'ResourceNotFoundException'
                  Fog::AWS::Kinesis::ResourceNotFound.slurp(error, match[:message])
                when 'ExpiredIteratorException'
                  Fog::AWS::Kinesis::ExpiredIterator.slurp(error, match[:message])
                when 'InvalidArgumentException'
                  Fog::AWS::Kinesis::InvalidArgument.slurp(error, match[:message])
                when 'ProvisionedThroughputExceededException'
                  Fog::AWS::Kinesis::ProvisionedThroughputExceeded.slurp(error, match[:message])
                else
                  Fog::AWS::Kinesis::Error.slurp(error, "#{match[:code]} => #{match[:message]}")
                end
        end

      end

      class Mock
        @mutex = Mutex.new

        def self.data
          @mutex.synchronize do
            @data ||= Hash.new do |hash, region|
              hash[region] = Hash.new do |region_hash, key|
                region_hash[key] = {
                  :kinesis_streams => {}
                }
              end
            end
            
            yield @data if block_given?
          end
        end

        def self.reset
          @mutex.synchronize do
            @data = nil
          end
        end

        def initialize(options={})
          @account_id        = Fog::AWS::Mock.owner_id
          @aws_access_key_id = options[:aws_access_key_id]
          @region            = options[:region] || 'us-east-1'

          Fog::AWS.validate_region!(@region)
        end

        def data
          self.class.data do |data|
            data[@region][@aws_access_key_id]
          end
        end

        def reset_data
          self.class.data do |data|
            data[@region].delete(@aws_access_key_id)
          end
        end

        def self.next_sequence_number
          @mutex.synchronize do
            @sequence_number ||= -1
            @sequence_number += 1
            @sequence_number.to_s
          end
        end
        
        def next_sequence_number; self.class.next_sequence_number; end

        def self.next_shard_id
          @mutex.synchronize do
            @shard_id ||= -1
            @shard_id += 1
            "shardId-#{@shard_id.to_s.rjust(12, "0")}"
          end
        end
        
        def next_shard_id; self.class.next_shard_id; end
      end

    end
  end
end
