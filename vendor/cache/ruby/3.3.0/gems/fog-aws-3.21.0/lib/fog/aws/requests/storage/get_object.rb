module Fog
  module AWS
    class Storage
      class Real
        # Get an object from S3
        #
        # @param bucket_name [String] Name of bucket to read from
        # @param object_name [String] Name of object to read
        # @param options [Hash]
        # @option options If-Match [String] Returns object only if its etag matches this value, otherwise returns 412 (Precondition Failed).
        # @option options If-Modified-Since [Time] Returns object only if it has been modified since this time, otherwise returns 304 (Not Modified).
        # @option options If-None-Match [String] Returns object only if its etag differs from this value, otherwise returns 304 (Not Modified)
        # @option options If-Unmodified-Since [Time] Returns object only if it has not been modified since this time, otherwise returns 412 (Precodition Failed).
        # @option options Range [String] Range of object to download
        # @option options versionId [String] specify a particular version to retrieve
        # @option options query[Hash] specify additional query string
        #
        # @return [Excon::Response] response:
        #   * body [String]- Contents of object
        #   * headers [Hash]:
        #     * Content-Length [String] - Size of object contents
        #     * Content-Type [String] - MIME type of object
        #     * ETag [String] - Etag of object
        #     * Last-Modified [String] - Last modified timestamp for object
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGET.html

        def get_object(bucket_name, object_name, options = {}, &block)
          unless bucket_name
            raise ArgumentError.new('bucket_name is required')
          end
          unless object_name
            raise ArgumentError.new('object_name is required')
          end

          params = { :headers => {} }

          params[:query] = options.delete('query') || {}

          if version_id = options.delete('versionId')
            params[:query] = params[:query].merge({'versionId' => version_id})
          end
          params[:headers].merge!(options)
          if options['If-Modified-Since']
            params[:headers]['If-Modified-Since'] = Fog::Time.at(options['If-Modified-Since'].to_i).to_date_header
          end
          if options['If-Unmodified-Since']
            params[:headers]['If-Unmodified-Since'] = Fog::Time.at(options['If-Unmodified-Since'].to_i).to_date_header
          end

          idempotent = true
          if block_given?
            params[:response_block] = Proc.new(&block)
            idempotent = false
          end

          request(params.merge!({
            :expects  => [ 200, 206 ],
            :bucket_name => bucket_name,
            :object_name => object_name,
            :idempotent => idempotent,
            :method   => 'GET',
          }))
        end
      end

      class Mock # :nodoc:all
        def get_object(bucket_name, object_name, options = {}, &block)
          version_id = options.delete('versionId')

          unless bucket_name
            raise ArgumentError.new('bucket_name is required')
          end

          unless object_name
            raise ArgumentError.new('object_name is required')
          end

          response = Excon::Response.new
          if (bucket = self.data[:buckets][bucket_name])
            object = nil
            if bucket[:objects].key?(object_name)
              object = version_id ? bucket[:objects][object_name].find { |object| object['VersionId'] == version_id} : bucket[:objects][object_name].first
            end

            if (object && !object[:delete_marker])
              if options['If-Match'] && options['If-Match'] != object['ETag']
                response.status = 412
                raise(Excon::Errors.status_error({:expects => 200}, response))
              elsif options['If-Modified-Since'] && options['If-Modified-Since'] >= Time.parse(object['Last-Modified'])
                response.status = 304
                raise(Excon::Errors.status_error({:expects => 200}, response))
              elsif options['If-None-Match'] && options['If-None-Match'] == object['ETag']
                response.status = 304
                raise(Excon::Errors.status_error({:expects => 200}, response))
              elsif options['If-Unmodified-Since'] && options['If-Unmodified-Since'] < Time.parse(object['Last-Modified'])
                response.status = 412
                raise(Excon::Errors.status_error({:expects => 200}, response))
              else
                response.status = 200
                for key, value in object
                  case key
                  when 'Cache-Control', 'Content-Disposition', 'Content-Encoding', 'Content-Length', 'Content-MD5', 'Content-Type', 'ETag', 'Expires', 'Last-Modified', /^x-amz-meta-/
                    response.headers[key] = value
                  end
                end

                response.headers['x-amz-version-id'] = object['VersionId'] if bucket[:versioning]

                body = object[:body]
                if options['Range']
                  # since AWS S3 itself does not support multiple range headers, we will use only the first
                  ranges = byte_ranges(options['Range'], body.size)
                  unless ranges.nil? || ranges.empty?
                    response.status = 206
                    body = body[ranges.first]
                  end
                end

                unless block_given?
                  response.body = body
                else
                  data = StringIO.new(body)
                  remaining = total_bytes = data.length
                  while remaining > 0
                    chunk = data.read([remaining, Excon::CHUNK_SIZE].min)
                    block.call(chunk, remaining, total_bytes)
                    remaining -= Excon::CHUNK_SIZE
                  end
                end
              end
            elsif version_id && !object
              response.status = 400
              response.body = {
                'Error' => {
                  'Code' => 'InvalidArgument',
                  'Message' => 'Invalid version id specified',
                  'ArgumentValue' => version_id,
                  'ArgumentName' => 'versionId',
                  'RequestId' => Fog::Mock.random_hex(16),
                  'HostId' => Fog::Mock.random_base64(65)
                }
              }

              raise(Excon::Errors.status_error({:expects => 200}, response))
            else
              response.status = 404
              response.body = "...<Code>NoSuchKey<\/Code>..."
              raise(Excon::Errors.status_error({:expects => 200}, response))
            end
          else
            response.status = 404
            response.body = "...<Code>NoSuchBucket</Code>..."
            raise(Excon::Errors.status_error({:expects => 200}, response))
          end
          response
        end

        private

        # === Borrowed from rack
        # Parses the "Range:" header, if present, into an array of Range objects.
        # Returns nil if the header is missing or syntactically invalid.
        # Returns an empty array if none of the ranges are satisfiable.
        def byte_ranges(http_range, size)
          # See <http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35>
          return nil unless http_range
          ranges = []
          http_range.split(/,\s*/).each do |range_spec|
            matches = range_spec.match(/bytes=(\d*)-(\d*)/)
            return nil  unless matches
            r0,r1 = matches[1], matches[2]
            if r0.empty?
              return nil  if r1.empty?
              # suffix-byte-range-spec, represents trailing suffix of file
              r0 = [size - r1.to_i, 0].max
              r1 = size - 1
            else
              r0 = r0.to_i
              if r1.empty?
                r1 = size - 1
              else
                r1 = r1.to_i
                return nil  if r1 < r0  # backwards range is syntactically invalid
                r1 = size-1  if r1 >= size
              end
            end
            ranges << (r0..r1)  if r0 <= r1
          end
          ranges
        end
      end
    end
  end
end
