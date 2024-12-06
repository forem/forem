module Fog
  module AWS
    class Storage < Fog::Service
      extend Fog::AWS::CredentialFetcher::ServiceMethods

      COMPLIANT_BUCKET_NAMES = /^(?:[a-z]|\d(?!\d{0,2}(?:\.\d{1,3}){3}$))(?:[a-z0-9]|\.(?![\.\-])|\-(?![\.])){1,61}[a-z0-9]$/

      DEFAULT_REGION = 'us-east-1'
      ACCELERATION_HOST = 's3-accelerate.amazonaws.com'

      DEFAULT_SCHEME = 'https'
      DEFAULT_SCHEME_PORT = {
        'http' => 80,
        'https' => 443
      }

      DEFAULT_CONNECTION_OPTIONS = {
        retry_limit: 5,
        retry_interval: 1,
        retry_errors: [
          Excon::Error::Timeout, Excon::Error::Socket, Excon::Error::Server
        ]
      }

      MIN_MULTIPART_CHUNK_SIZE = 5242880
      MAX_SINGLE_PUT_SIZE = 5368709120

      VALID_QUERY_KEYS = %w[
        acl
        cors
        delete
        lifecycle
        location
        logging
        notification
        partNumber
        policy
        requestPayment
        response-cache-control
        response-content-disposition
        response-content-encoding
        response-content-language
        response-content-type
        response-expires
        restore
        tagging
        torrent
        uploadId
        uploads
        versionId
        versioning
        versions
        website
      ]

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :endpoint, :region, :host, :port, :scheme, :persistent, :use_iam_profile, :aws_session_token, :aws_credentials_expire_at, :path_style, :acceleration, :instrumentor, :instrumentor_name, :aws_signature_version, :enable_signature_v4_streaming, :virtual_host, :cname, :max_put_chunk_size, :max_copy_chunk_size, :aws_credentials_refresh_threshold_seconds, :disable_content_md5_validation, :sts_endpoint

      secrets    :aws_secret_access_key, :hmac

      model_path 'fog/aws/models/storage'
      collection  :directories
      model       :directory
      collection  :files
      model       :file

      request_path 'fog/aws/requests/storage'
      request :abort_multipart_upload
      request :complete_multipart_upload
      request :copy_object
      request :delete_bucket
      request :delete_bucket_cors
      request :delete_bucket_lifecycle
      request :delete_bucket_policy
      request :delete_bucket_website
      request :delete_object
      request :delete_object_url
      request :delete_multiple_objects
      request :delete_bucket_tagging
      request :get_bucket
      request :get_bucket_acl
      request :get_bucket_cors
      request :get_bucket_lifecycle
      request :get_bucket_location
      request :get_bucket_logging
      request :get_bucket_object_versions
      request :get_bucket_policy
      request :get_bucket_tagging
      request :get_bucket_versioning
      request :get_bucket_website
      request :get_bucket_notification
      request :get_object
      request :get_object_acl
      request :get_object_torrent
      request :get_object_http_url
      request :get_object_https_url
      request :get_object_url
      request :get_object_tagging
      request :get_request_payment
      request :get_service
      request :head_bucket
      request :head_object
      request :head_object_url
      request :initiate_multipart_upload
      request :list_multipart_uploads
      request :list_parts
      request :post_object_hidden_fields
      request :post_object_restore
      request :put_bucket
      request :put_bucket_acl
      request :put_bucket_cors
      request :put_bucket_lifecycle
      request :put_bucket_logging
      request :put_bucket_policy
      request :put_bucket_tagging
      request :put_bucket_versioning
      request :put_bucket_website
      request :put_bucket_notification
      request :put_object
      request :put_object_acl
      request :put_object_url
      request :put_object_tagging
      request :put_request_payment
      request :sync_clock
      request :upload_part
      request :upload_part_copy

      module Utils
        attr_accessor :region
        attr_accessor :disable_content_md5_validation

        # Amazon S3 limits max chunk size that can be uploaded/copied in a single request to 5GB.
        # Other S3-compatible storages (like, Ceph) do not have such limit.
        # Ceph shows much better performance when file is copied as a whole, in a single request.
        # fog-aws user can use these settings to configure chunk sizes.
        # A non-positive value will tell fog-aws to use a single put/copy request regardless of file size.
        #
        # @return [Integer]
        # @see https://docs.aws.amazon.com/AmazonS3/latest/userguide/copy-object.html
        attr_reader :max_put_chunk_size
        attr_reader :max_copy_chunk_size

        def cdn
          @cdn ||= Fog::AWS::CDN.new(
            :aws_access_key_id => @aws_access_key_id,
            :aws_secret_access_key => @aws_secret_access_key,
            :use_iam_profile => @use_iam_profile
          )
        end

        def http_url(params, expires)
          signed_url(params.merge(:scheme => 'http'), expires)
        end

        def https_url(params, expires)
          signed_url(params.merge(:scheme => 'https'), expires)
        end

        def url(params, expires)
          Fog::Logger.deprecation("Fog::AWS::Storage => #url is deprecated, use #https_url instead [light_black](#{caller.first})[/]")
          https_url(params, expires)
        end

        def require_mime_types
          begin
            # Use mime/types/columnar if available, for reduced memory usage
            require 'mime/types/columnar'
          rescue LoadError
            begin
              require 'mime/types'
            rescue LoadError
              Fog::Logger.warning("'mime-types' missing, please install and try again.")
              exit(1)
            end
          end
        end

        def request_url(params)
          params = request_params(params)
          params_to_url(params)
        end

        def signed_url(params, expires)
          refresh_credentials_if_expired

          #convert expires from a point in time to a delta to now
          expires = expires.to_i
          if @signature_version == 4
            params = v4_signed_params_for_url(params, expires)
          else
            params = v2_signed_params_for_url(params, expires)
          end

          params_to_url(params)
        end

        # @param value [int]
        # @param description [str]
        def validate_chunk_size(value, description)
          raise "#{description} (#{value}) is less than minimum #{MIN_MULTIPART_CHUNK_SIZE}" unless value <= 0 || value >= MIN_MULTIPART_CHUNK_SIZE
        end

        private

        def validate_signature_version!
          unless @signature_version == 2 || @signature_version == 4
            raise "Unknown signature version #{@signature_version}; valid versions are 2 or 4"
          end
        end

        def init_max_put_chunk_size!(options = {})
          @max_put_chunk_size = options.fetch(:max_put_chunk_size, MAX_SINGLE_PUT_SIZE)
          validate_chunk_size(@max_put_chunk_size, 'max_put_chunk_size')
        end

        def init_max_copy_chunk_size!(options = {})
          @max_copy_chunk_size = options.fetch(:max_copy_chunk_size, MAX_SINGLE_PUT_SIZE)
          validate_chunk_size(@max_copy_chunk_size, 'max_copy_chunk_size')
        end

        def v4_signed_params_for_url(params, expires)
          now = Fog::Time.now

          expires = expires - now.to_i
          params[:headers] ||= {}

          params[:query]||= {}
          params[:query]['X-Amz-Expires'] = expires
          params[:query]['X-Amz-Date'] = now.to_iso8601_basic

          if @aws_session_token
            params[:query]['X-Amz-Security-Token'] = @aws_session_token
          end

          params = request_params(params)
          params[:headers][:host] = params[:host]
          params[:headers][:host] += ":#{params[:port]}" if params.fetch(:port, nil)

          signature_query_params = @signer.signature_parameters(params, now, "UNSIGNED-PAYLOAD")
          params[:query] = (params[:query] || {}).merge(signature_query_params)
          params
        end

        def v2_signed_params_for_url(params, expires)
          if @aws_session_token
            params[:headers]||= {}
            params[:headers]['x-amz-security-token'] = @aws_session_token
          end
          signature = signature_v2(params, expires)

          params = request_params(params)

          signature_query_params = {
            'AWSAccessKeyId' => @aws_access_key_id,
            'Signature' => signature,
            'Expires' => expires,
          }
          params[:query] = (params[:query] || {}).merge(signature_query_params)
          params[:query]['x-amz-security-token'] = @aws_session_token if @aws_session_token
          params
        end

        def region_to_host(region=nil)
          case region.to_s
          when DEFAULT_REGION, ''
            's3.amazonaws.com'
          when %r{\Acn-.*}
            "s3.#{region}.amazonaws.com.cn"
          else
            "s3.#{region}.amazonaws.com"
          end
        end

        def object_to_path(object_name=nil)
          '/' + escape(object_name.to_s).gsub('%2F','/')
        end

        def bucket_to_path(bucket_name, path=nil)
          "/#{escape(bucket_name.to_s)}#{path}"
        end

        # NOTE: differs from Fog::AWS.escape by NOT escaping `/`
        def escape(string)
          string.gsub(/([^a-zA-Z0-9_.\-~\/]+)/) {
            "%" + $1.unpack("H2" * $1.bytesize).join("%").upcase
          }
        end

        # Transforms things like bucket_name, object_name, region
        #
        # Should yield the same result when called f*f
        def request_params(params)
          headers  = params[:headers] || {}

          if params[:scheme]
            scheme = params[:scheme]
            port   = params[:port] || DEFAULT_SCHEME_PORT[scheme]
          else
            scheme = @scheme
            port   = @port
          end
          if DEFAULT_SCHEME_PORT[scheme] == port
            port = nil
          end

          if params[:region]
            region = params[:region]
            host   = params[:host] || region_to_host(region)
          else
            region = @region       || DEFAULT_REGION
            host   = params[:host] || @host || region_to_host(region)
          end

          path     = params[:path] || object_to_path(params[:object_name])
          path     = '/' + path if path[0..0] != '/'

          if params[:bucket_name]
            bucket_name = params[:bucket_name]

            if params[:bucket_cname]
              host = bucket_name
            else
              path_style = params.fetch(:path_style, @path_style)
              if !path_style
                if COMPLIANT_BUCKET_NAMES !~ bucket_name
                  Fog::Logger.warning("fog: the specified s3 bucket name(#{bucket_name}) is not a valid dns name, which will negatively impact performance.  For details see: https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html")
                  path_style = true
                elsif scheme == 'https' && !path_style && bucket_name =~ /\./
                  Fog::Logger.warning("fog: the specified s3 bucket name(#{bucket_name}) contains a '.' so is not accessible over https as a virtual hosted bucket, which will negatively impact performance.  For details see: https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html")
                  path_style = true
                end
              end

              # uses the bucket name as host if `virtual_host: true`, you can also
              # manually specify the cname if required.
              if params[:virtual_host]
                host = params.fetch(:cname, bucket_name)
              elsif path_style
                path = bucket_to_path bucket_name, path
              elsif host.start_with?("#{bucket_name}.")
                # no-op
              else
                host = [bucket_name, host].join('.')
              end
            end
          end

          ret = params.merge({
            :scheme       => scheme,
            :host         => host,
            :port         => port,
            :path         => path,
            :headers      => headers
          })

          #
          ret.delete(:path_style)
          ret.delete(:bucket_name)
          ret.delete(:object_name)
          ret.delete(:region)

          ret
        end

        def params_to_url(params)
          query = params[:query] && params[:query].map do |key, value|
            if value
              # URL parameters need / to be escaped
              [key, Fog::AWS.escape(value.to_s)].join('=')
            else
              key
            end
          end.join('&')

          URI::Generic.build({
            :scheme => params[:scheme],
            :host   => params[:host],
            :port   => params[:port],
            :path   => params[:path],
            :query  => query,
          }).to_s
        end
      end

      class Mock
        include Utils
        include Fog::AWS::CredentialFetcher::ConnectionMethods

        def self.acls(type)
          case type
          when 'private'
            {
              "AccessControlList" => [
                {
                  "Permission" => "FULL_CONTROL",
                  "Grantee" => {"DisplayName" => "me", "ID" => "2744ccd10c7533bd736ad890f9dd5cab2adb27b07d500b9493f29cdc420cb2e0"}
                }
              ],
              "Owner" => {"DisplayName" => "me", "ID" => "2744ccd10c7533bd736ad890f9dd5cab2adb27b07d500b9493f29cdc420cb2e0"}
            }
          when 'public-read'
            {
              "AccessControlList" => [
                {
                  "Permission" => "FULL_CONTROL",
                  "Grantee" => {"DisplayName" => "me", "ID" => "2744ccd10c7533bd736ad890f9dd5cab2adb27b07d500b9493f29cdc420cb2e0"}
                },
                {
                  "Permission" => "READ",
                  "Grantee" => {"URI" => "http://acs.amazonaws.com/groups/global/AllUsers"}
                }
              ],
              "Owner" => {"DisplayName" => "me", "ID" => "2744ccd10c7533bd736ad890f9dd5cab2adb27b07d500b9493f29cdc420cb2e0"}
            }
          when 'public-read-write'
            {
              "AccessControlList" => [
                {
                  "Permission" => "FULL_CONTROL",
                  "Grantee" => {"DisplayName" => "me", "ID" => "2744ccd10c7533bd736ad890f9dd5cab2adb27b07d500b9493f29cdc420cb2e0"}
                },
                {
                  "Permission" => "READ",
                  "Grantee" => {"URI" => "http://acs.amazonaws.com/groups/global/AllUsers"}
                },
                {
                  "Permission" => "WRITE",
                  "Grantee" => {"URI" => "http://acs.amazonaws.com/groups/global/AllUsers"}
                }
              ],
              "Owner" => {"DisplayName" => "me", "ID" => "2744ccd10c7533bd736ad890f9dd5cab2adb27b07d500b9493f29cdc420cb2e0"}
            }
          when 'authenticated-read'
            {
              "AccessControlList" => [
                {
                  "Permission" => "FULL_CONTROL",
                  "Grantee" => {"DisplayName" => "me", "ID" => "2744ccd10c7533bd736ad890f9dd5cab2adb27b07d500b9493f29cdc420cb2e0"}
                },
                {
                  "Permission" => "READ",
                  "Grantee" => {"URI" => "http://acs.amazonaws.com/groups/global/AuthenticatedUsers"}
                }
              ],
              "Owner" => {"DisplayName" => "me", "ID" => "2744ccd10c7533bd736ad890f9dd5cab2adb27b07d500b9493f29cdc420cb2e0"}
            }
          end
        end

        def self.data
          @data ||= Hash.new do |hash, region|
            hash[region] = Hash.new do |region_hash, key|
              region_hash[key] = {
                :acls => {
                  :bucket => {},
                  :object => {}
                },
                :buckets => {},
                :cors => {
                  :bucket => {}
                },
                :bucket_notifications => {},
                :bucket_tagging => {},
                :multipart_uploads => {}
              }
            end
          end
        end

        def self.reset
          @data = nil
        end

        def initialize(options={})
          require_mime_types

          @use_iam_profile = options[:use_iam_profile]

          @region = options[:region] || DEFAULT_REGION

          if @endpoint = options[:endpoint]
            endpoint = URI.parse(@endpoint)
            @host = endpoint.host
            @scheme = endpoint.scheme
            @port = endpoint.port
          else
            @host       = options[:host]        || region_to_host(@region)
            @scheme     = options[:scheme]      || DEFAULT_SCHEME
            @port       = options[:port]        || DEFAULT_SCHEME_PORT[@scheme]
          end


          @path_style = options[:path_style] || false

          init_max_put_chunk_size!(options)
          init_max_copy_chunk_size!(options)

          @disable_content_md5_validation = options[:disable_content_md5_validation] || false

          @signature_version = options.fetch(:aws_signature_version, 4)
          validate_signature_version!
          setup_credentials(options)
        end

        def data
          self.class.data[@region][@aws_access_key_id]
        end

        def reset_data
          self.class.data[@region].delete(@aws_access_key_id)
        end

        def setup_credentials(options)
          @aws_credentials_refresh_threshold_seconds = options[:aws_credentials_refresh_threshold_seconds]

          @aws_access_key_id = options[:aws_access_key_id]
          @aws_secret_access_key = options[:aws_secret_access_key]
          @aws_session_token     = options[:aws_session_token]
          @aws_credentials_expire_at = options[:aws_credentials_expire_at]

          @signer = Fog::AWS::SignatureV4.new( @aws_access_key_id, @aws_secret_access_key, @region, 's3')
        end

        def signature_v2(params, expires)
          'foo'
        end

      end

      class Real
        include Utils
        include Fog::AWS::CredentialFetcher::ConnectionMethods
        # Initialize connection to S3
        #
        # ==== Notes
        # options parameter must include values for :aws_access_key_id and
        # :aws_secret_access_key in order to create a connection
        #
        # ==== Examples
        #   s3 = Fog::Storage.new(
        #     :provider => "AWS",
        #     :aws_access_key_id => your_aws_access_key_id,
        #     :aws_secret_access_key => your_aws_secret_access_key
        #   )
        #
        # ==== Parameters
        # * options<~Hash> - config arguments for connection.  Defaults to {}.
        #
        # ==== Returns
        # * S3 object with connection to aws.
        def initialize(options={})
          require_mime_types

          @use_iam_profile = options[:use_iam_profile]
          @instrumentor       = options[:instrumentor]
          @instrumentor_name  = options[:instrumentor_name] || 'fog.aws.storage'
          @connection_options =
            DEFAULT_CONNECTION_OPTIONS.merge(options[:connection_options] || {})
          @persistent = options.fetch(:persistent, false)
          @acceleration = options.fetch(:acceleration, false)
          @signature_version = options.fetch(:aws_signature_version, 4)
          @enable_signature_v4_streaming = options.fetch(:enable_signature_v4_streaming, true)
          validate_signature_version!
          @path_style = options[:path_style]  || false

          init_max_put_chunk_size!(options)
          init_max_copy_chunk_size!(options)

          @disable_content_md5_validation = options[:disable_content_md5_validation] || false

          @region = options[:region] || DEFAULT_REGION

          if @endpoint = options[:endpoint]
            endpoint = URI.parse(@endpoint)
            @host = endpoint.host
            @scheme = endpoint.scheme
            @port = endpoint.port
          else
            @host       = options[:host]        || region_to_host(@region)
            @scheme     = options[:scheme]      || DEFAULT_SCHEME
            @port       = options[:port]        || DEFAULT_SCHEME_PORT[@scheme]
          end

          @host = ACCELERATION_HOST if @acceleration
          setup_credentials(options)
        end

        def reload
          @connection.reset if @connection
        end

        private


        def setup_credentials(options)
          @aws_credentials_refresh_threshold_seconds = options[:aws_credentials_refresh_threshold_seconds]

          @aws_access_key_id     = options[:aws_access_key_id]
          @aws_secret_access_key = options[:aws_secret_access_key]
          @aws_session_token     = options[:aws_session_token]
          @aws_credentials_expire_at = options[:aws_credentials_expire_at]

          if @signature_version == 4
            @signer = Fog::AWS::SignatureV4.new( @aws_access_key_id, @aws_secret_access_key, @region, 's3')
          elsif @signature_version == 2
            @hmac = Fog::HMAC.new('sha1', @aws_secret_access_key)
          end
        end

        def connection(scheme, host, port)
          uri = "#{scheme}://#{host}:#{port}"
          if @persistent
            unless uri == @connection_uri
              @connection_uri = uri
              reload
              @connection = nil
            end
          else
            @connection = nil
          end
          @connection ||= Fog::XML::Connection.new(uri, @persistent, @connection_options)
        end

        def request(params, &block)
          refresh_credentials_if_expired

          date = Fog::Time.now

          params = params.dup
          stringify_query_keys(params)
          params[:headers] = (params[:headers] || {}).dup

          params[:headers]['x-amz-security-token'] = @aws_session_token if @aws_session_token

          if @signature_version == 2
            expires = date.to_date_header
            params[:headers]['Date'] = expires
            params[:headers]['Authorization'] = "AWS #{@aws_access_key_id}:#{signature_v2(params, expires)}"
          end

          params = request_params(params)
          scheme = params.delete(:scheme)
          host   = params.delete(:host)
          port   = params.delete(:port) || DEFAULT_SCHEME_PORT[scheme]
          params[:headers]['Host'] = host


          if @signature_version == 4
            params[:headers]['x-amz-date'] = date.to_iso8601_basic
            if params[:body].respond_to?(:read)
              if @enable_signature_v4_streaming
                # See http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-streaming.html
                # We ignore the bit about setting the content-encoding to aws-chunked because
                # this can cause s3 to serve files with a blank content encoding which causes problems with some CDNs
                # AWS have confirmed that s3 can infer that the content-encoding is aws-chunked from the x-amz-content-sha256 header
                #
                params[:headers]['x-amz-content-sha256'] = 'STREAMING-AWS4-HMAC-SHA256-PAYLOAD'
                params[:headers]['x-amz-decoded-content-length'] = params[:headers].delete 'Content-Length'
              else
                params[:headers]['x-amz-content-sha256'] = 'UNSIGNED-PAYLOAD'
              end
            else
              params[:headers]['x-amz-content-sha256'] ||= OpenSSL::Digest::SHA256.hexdigest(params[:body] || '')
            end
            signature_components = @signer.signature_components(params, date, params[:headers]['x-amz-content-sha256'])
            params[:headers]['Authorization'] = @signer.components_to_header(signature_components)

            if params[:body].respond_to?(:read) && @enable_signature_v4_streaming
              body = params.delete :body
              params[:request_block] = S3Streamer.new(body, signature_components['X-Amz-Signature'], @signer, date)
            end
          end
          # FIXME: ToHashParser should make this not needed
          original_params = params.dup

          if @instrumentor
            @instrumentor.instrument("#{@instrumentor_name}.request", params) do
              _request(scheme, host, port, params, original_params, &block)
            end
          else
              _request(scheme, host, port, params, original_params, &block)
          end
        end

        def _request(scheme, host, port, params, original_params, &block)
          connection(scheme, host, port).request(params, &block)
        rescue Excon::Errors::MovedPermanently, Excon::Errors::TemporaryRedirect => error
          headers = (error.response.is_a?(Hash) ? error.response[:headers] : error.response.headers)
          new_params = {}
          if headers.has_key?('Location')
            new_params[:host] = URI.parse(headers['Location']).host
          else
            body = error.response.is_a?(Hash) ? error.response[:body] : error.response.body
            # some errors provide info indirectly
            new_params[:bucket_name] =  %r{<Bucket>([^<]*)</Bucket>}.match(body).captures.first
            new_params[:host] = %r{<Endpoint>([^<]*)</Endpoint>}.match(body).captures.first
            # some errors provide it directly
            @new_region = %r{<Region>([^<]*)</Region>}.match(body) ? Regexp.last_match.captures.first : nil
          end
          Fog::Logger.warning("fog: followed redirect to #{host}, connecting to the matching region will be more performant")
          original_region, original_signer = @region, @signer
          @region = @new_region || case new_params[:host]
          when /s3.amazonaws.com/, /s3-external-1.amazonaws.com/
            DEFAULT_REGION
          else
            %r{s3[\.\-]([^\.]*).amazonaws.com}.match(new_params[:host]).captures.first
          end
          if @signature_version == 4
            @signer = Fog::AWS::SignatureV4.new(@aws_access_key_id, @aws_secret_access_key, @region, 's3')
            original_params[:headers].delete('Authorization')
          end
          response = request(original_params.merge(new_params), &block)
          @region, @signer = original_region, original_signer
          response
        end

        # See http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-streaming.html

        class S3Streamer
          attr_accessor :body, :signature, :signer, :finished, :date, :initial_signature
          def initialize(body, signature, signer, date)
            self.body = body
            self.date = date
            self.signature = signature
            self.initial_signature = signature
            self.signer = signer
            if body.respond_to?(:binmode)
              body.binmode
            end

            if body.respond_to?(:pos=)
              body.pos = 0
            end

          end

          #called if excon wants to retry the request. As well as rewinding the body
          #we must also reset the signature
          def rewind
            self.signature = initial_signature
            self.finished = false
            body.rewind
          end

          def call
            if finished
              ''
            else
              next_chunk
            end
          end

          def next_chunk
            data = body.read(0x10000)
            if data.nil?
              self.finished = true
              data = ''
            end
            self.signature = sign_chunk(data, signature)
            "#{data.length.to_s(16)};chunk-signature=#{signature}\r\n#{data}\r\n"
          end


          def sign_chunk(data, previous_signature)
            string_to_sign = <<-DATA
AWS4-HMAC-SHA256-PAYLOAD
#{date.to_iso8601_basic}
#{signer.credential_scope(date)}
#{previous_signature}
#{OpenSSL::Digest::SHA256.hexdigest('')}
#{OpenSSL::Digest::SHA256.hexdigest(data)}
DATA
            hmac = signer.derived_hmac(date)
            hmac.sign(string_to_sign.strip).unpack('H*').first
          end
        end

        def signature_v2(params, expires)
          headers = params[:headers] || {}

          string_to_sign =
<<-DATA
#{params[:method].to_s.upcase}
#{headers['Content-MD5']}
#{headers['Content-Type']}
#{expires}
DATA

          amz_headers, canonical_amz_headers = {}, ''
          for key, value in headers
            if key[0..5] == 'x-amz-'
              amz_headers[key] = value
            end
          end
          amz_headers = amz_headers.sort {|x, y| x[0] <=> y[0]}
          for key, value in amz_headers
            canonical_amz_headers << "#{key}:#{value}\n"
          end
          string_to_sign << canonical_amz_headers

          query_string = ''
          if params[:query]
            query_args = []
            for key in params[:query].keys.sort
              if VALID_QUERY_KEYS.include?(key)
                value = params[:query][key]
                if value
                  query_args << "#{key}=#{value}"
                else
                  query_args << key
                end
              end
            end
            if query_args.any?
              query_string = '?' + query_args.join('&')
            end
          end

          canonical_path = (params[:path] || object_to_path(params[:object_name])).to_s
          canonical_path = '/' + canonical_path if canonical_path[0..0] != '/'

          if params[:bucket_name]
            canonical_resource = "/#{params[:bucket_name]}#{canonical_path}"
          else
            canonical_resource = canonical_path
          end
          canonical_resource << query_string
          string_to_sign << canonical_resource
          signed_string = @hmac.sign(string_to_sign)
          Base64.encode64(signed_string).chomp!
        end

        def stringify_query_keys(params)
          params[:query] = Hash[params[:query].map { |k,v| [k.to_s, v] }] if params[:query]
        end
      end
    end
  end

  # @deprecated
  module Storage
    # @deprecated
    class AWS < Fog::AWS::Storage
      # @deprecated
      # @overrides Fog::Service.new (from the fog-core gem)
      def self.new(*)
        Fog::Logger.deprecation 'Fog::Storage::AWS is deprecated, please use Fog::AWS::Storage.'
        super
      end
    end
  end
end
