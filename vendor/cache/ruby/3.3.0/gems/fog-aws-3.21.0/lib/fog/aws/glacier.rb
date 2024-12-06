module Fog
  module AWS
    class Glacier < Fog::Service
      extend Fog::AWS::CredentialFetcher::ServiceMethods

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :region, :host, :path, :port, :scheme, :persistent, :use_iam_profile, :aws_session_token, :aws_credentials_expire_at, :instrumentor, :instrumentor_name, :sts_endpoint

      request_path 'fog/aws/requests/glacier'

      request :abort_multipart_upload
      request :complete_multipart_upload
      request :create_archive
      request :create_vault
      request :delete_archive
      request :delete_vault
      request :delete_vault_notification_configuration
      request :describe_job
      request :describe_vault
      request :get_job_output
      request :get_vault_notification_configuration
      request :initiate_job
      request :initiate_multipart_upload
      request :list_jobs
      request :list_multipart_uploads
      request :list_parts
      request :list_vaults
      request :set_vault_notification_configuration
      request :upload_part

      model_path 'fog/aws/models/glacier'
      model      :vault
      collection :vaults

      MEGABYTE = 1024*1024

      class TreeHash
        def self.digest(body)
          new.add_part(body)
        end

        def initialize
          @last_chunk_digest = nil	# Digest OBJECT for last chunk (Digest::SHA256)
          @last_chunk_digest_temp = nil	# Digest VALUE for last chunk
          @last_chunk_length = 0	# Length of last chunk, always smaller than 1MB.
          @digest_stack = []
          # First position on stack corresponds to 1MB, second 2MB, third 4MB, fourt 8MB and so on.
          # In any time, the size of all already added parts is equal to sum of all existing (non-nil)
          # positions multiplied by that number, plus last_chunk_length for the remainder smaller than
          # one megabyte. So, if last_chunk_length is half megabyte, stack[0] is filled, stack[1] and 
          # stack[2] empty and stack[3] filled, the size is 0.5MB + 1x1MB + 0x2MB + 0x4MB + 1x8MB = 9.5MB.
        end

        def update_digest_stack(digest, stack)
          stack.each_with_index{|s,i|
            if s
              digest = Digest::SHA256.digest(s + digest)
              stack[i] = nil
            else
              stack[i] = digest # Update this position with value obtained in previous run of cycle.
              digest = nil
              break
            end
          }
          stack << digest if digest
        end

        def reduce_digest_stack(digest, stack)
          stack.each_with_index{|s,i|
            unless digest
              digest = stack[i]
              next
            end
            if stack[i]
              digest = Digest::SHA256.digest(stack[i] + digest)
            end
          }
          digest
        end

        def add_part(bytes)
          part = self.digest_for_part(bytes)
          part.unpack('H*').first
        end

        def prepare_body_for_slice(body)
          if body.respond_to? :byteslice
            r = yield(body, :byteslice)
          else
            if body.respond_to? :encoding
              old_encoding = body.encoding
              body.force_encoding('BINARY')
            end
            r = yield(body, :slice)
            if body.respond_to? :encoding
              body.force_encoding(old_encoding)
            end
          end
          r
        end

        def digest_for_part(body)
          part_stack = []
          part_temp = nil
          body_size = body.bytesize
          prepare_body_for_slice(body) {|body, slice|
            start_offset = 0
            if @last_chunk_length != 0
              start_offset = MEGABYTE - @last_chunk_length
              @last_chunk_hash.update(body.send(slice, 0, start_offset))
              hash = @last_chunk_hash.digest
              @last_chunk_digest_temp = hash
              if body_size > start_offset
                @last_chunk_length = 0
                @last_chunk_hash = nil
                @last_chunk_digest_temp = nil
                update_digest_stack(hash, @digest_stack)
              else
                part_temp = hash
                @last_chunk_digest_temp = hash
                @last_chunk_length += body_size
                next
              end
            end
            whole_chunk_count = (body_size - start_offset) / MEGABYTE
            whole_chunk_count.times.each {|chunk_index|
              hash = Digest::SHA256.digest(body.send(slice, start_offset + chunk_index * MEGABYTE, MEGABYTE))
              update_digest_stack(hash, part_stack)
              update_digest_stack(hash, @digest_stack)
            }
            rest_size = body_size - start_offset - whole_chunk_count * MEGABYTE
            if rest_size > 0 || whole_chunk_count == 0
              @last_chunk_hash = Digest::SHA256.new
              @last_chunk_length = rest_size
              @last_chunk_hash.update(body.send(slice, start_offset + whole_chunk_count * MEGABYTE, rest_size))
              hash = @last_chunk_hash.digest
              @last_chunk_digest_temp = hash
              part_temp = hash
            end
          }
          reduce_digest_stack(part_temp, part_stack)
        end

        def digest
          reduce_digest_stack(@last_chunk_digest_temp, @digest_stack)
        end

        def hexdigest
          digest.unpack('H*').first
        end
      end

      class Mock
        def initialize(options={})
          Fog::Mock.not_implemented
        end
      end

      class Real
        include Fog::AWS::CredentialFetcher::ConnectionMethods
        # Initialize connection to Glacier
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
        # * Glacier object with connection to AWS.
        def initialize(options={})
          @use_iam_profile = options[:use_iam_profile]
          @region = options[:region] || 'us-east-1'

          setup_credentials(options)

          @instrumentor           = options[:instrumentor]
          @instrumentor_name      = options[:instrumentor_name] || 'fog.aws.glacier'
          @connection_options     = options[:connection_options] || {}
          @host = options[:host] || "glacier.#{@region}.amazonaws.com"
          @version = '2012-06-01'
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

          @signer = Fog::AWS::SignatureV4.new( @aws_access_key_id, @aws_secret_access_key,@region,'glacier')
        end

        def request(params, &block)
          refresh_credentials_if_expired

          date = Fog::Time.now
          params[:headers]['Date'] = date.to_date_header
          params[:headers]['x-amz-date'] = date.to_iso8601_basic

          params[:headers]['Host'] = @host
          params[:headers]['x-amz-glacier-version'] = @version
          params[:headers]['x-amz-security-token'] = @aws_session_token if @aws_session_token
          params[:headers]['Authorization'] = @signer.sign params, date

          if @instrumentor
            @instrumentor.instrument("#{@instrumentor_name}.request", params) do
              _request(params, &block)
            end
          else
            _request(params, &block)
          end
        end

        def _request(params, &block)
          response = @connection.request(params, &block)
          if response.headers['Content-Type'] == 'application/json' && response.body.size > 0 #body will be empty if the streaming form has been used
            response.body  = Fog::JSON.decode(response.body)
          end
          response
        end
      end
    end
  end
end
