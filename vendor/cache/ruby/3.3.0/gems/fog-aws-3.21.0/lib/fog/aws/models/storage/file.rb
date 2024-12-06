require 'fog/aws/models/storage/versions'

module Fog
  module AWS
    class Storage
      class File < Fog::Model
        # @deprecated use {Fog::AWS::Storage::MIN_MULTIPART_CHUNK_SIZE} instead
        MIN_MULTIPART_CHUNK_SIZE = Fog::AWS::Storage::MIN_MULTIPART_CHUNK_SIZE
        # @deprecated use {Fog::AWS::Storage::MAX_SINGLE_PUT_SIZE} instead
        MAX_SINGLE_PUT_SIZE = Fog::AWS::Storage::MAX_SINGLE_PUT_SIZE
        # @deprecated not used for anything
        MULTIPART_COPY_THRESHOLD = 15728640

        # @see AWS Object docs http://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectOps.html

        identity  :key,             :aliases => 'Key'

        attr_writer :body
        attribute :cache_control,       :aliases => 'Cache-Control'
        attribute :content_disposition, :aliases => 'Content-Disposition'
        attribute :content_encoding,    :aliases => 'Content-Encoding'
        attribute :content_length,      :aliases => ['Content-Length', 'Size'], :type => :integer
        attribute :content_md5,         :aliases => 'Content-MD5'
        attribute :content_type,        :aliases => 'Content-Type'
        attribute :etag,                :aliases => ['Etag', 'ETag']
        attribute :expires,             :aliases => 'Expires'
        attribute :last_modified,       :aliases => ['Last-Modified', 'LastModified']
        attribute :metadata
        attribute :owner,               :aliases => 'Owner'
        attribute :storage_class,       :aliases => ['x-amz-storage-class', 'StorageClass']
        attribute :encryption,          :aliases => 'x-amz-server-side-encryption'
        attribute :encryption_key,      :aliases => 'x-amz-server-side-encryption-customer-key'
        attribute :version,             :aliases => 'x-amz-version-id'
        attribute :kms_key_id,          :aliases => 'x-amz-server-side-encryption-aws-kms-key-id'
        attribute :tags,                :aliases => 'x-amz-tagging'
        attribute :website_redirect_location, :aliases => 'x-amz-website-redirect-location'

        UploadPartData = Struct.new(:part_number, :upload_options, :etag)

        class PartList
          def initialize(parts = [])
            @parts = parts
            @mutex = Mutex.new
          end

          def push(part)
            @mutex.synchronize { @parts.push(part) }
          end

          def shift
            @mutex.synchronize { @parts.shift }
          end

          def clear!
            @mutex.synchronize { @parts.clear }
          end

          def size
            @mutex.synchronize { @parts.size }
          end

          def to_a
            @mutex.synchronize { @parts.dup }
          end
        end

        # @note Chunk size to use for multipart uploads.
        #     Use small chunk sizes to minimize memory. E.g. 5242880 = 5mb
        attr_reader :multipart_chunk_size
        def multipart_chunk_size=(mp_chunk_size)
          service.validate_chunk_size(mp_chunk_size, 'multipart_chunk_size')
          @multipart_chunk_size = mp_chunk_size
        end

        # @note Number of threads used to copy files.
        def concurrency=(concurrency)
          raise ArgumentError.new('minimum concurrency is 1') if concurrency.to_i < 1

          @concurrency = concurrency.to_i
        end

        def concurrency
          @concurrency || 1
        end

        def acl
          requires :directory, :key
          service.get_object_acl(directory.key, key).body['AccessControlList']
        end

        # Set file's access control list (ACL).
        #
        #     valid acls: private, public-read, public-read-write, authenticated-read, bucket-owner-read, bucket-owner-full-control
        #
        # @param [String] new_acl one of valid options
        # @return [String] @acl
        #
        def acl=(new_acl)
          valid_acls = ['private', 'public-read', 'public-read-write', 'authenticated-read', 'bucket-owner-read', 'bucket-owner-full-control']
          unless valid_acls.include?(new_acl)
            raise ArgumentError.new("acl must be one of [#{valid_acls.join(', ')}]")
          end
          @acl = new_acl
        end

        # Get file's body if exists, else ''.
        #
        # @return [File]
        #
        def body
          return attributes[:body] if attributes.key?(:body)

          file = collection.get(identity)

          attributes[:body] =
            if file
              file.body
            else
              ''
            end
        end

        # Set body attribute.
        #
        # @param [File] new_body
        # @return [File] attributes[:body]
        #
        def body=(new_body)
          attributes[:body] = new_body
        end

        # Get the file instance's directory.
        #
        # @return [Fog::AWS::Storage::Directory]
        #
        def directory
          @directory
        end

        # Copy object from one bucket to other bucket.
        #
        #     required attributes: directory, key
        #
        # @param target_directory_key [String]
        # @param target_file_key [String]
        # @param options [Hash] options for copy_object method
        # @return [String] Fog::AWS::Files#head status of directory contents
        #
        def copy(target_directory_key, target_file_key, options = {})
          requires :directory, :key

          self.multipart_chunk_size = service.max_copy_chunk_size if multipart_chunk_size.nil?

          if multipart_chunk_size > 0 && self.content_length.to_i >= multipart_chunk_size
            upload_part_options = options.select { |key, _| ALLOWED_UPLOAD_PART_OPTIONS.include?(key.to_sym) }
            upload_part_options = upload_part_options.merge({ 'x-amz-copy-source' => "#{directory.key}/#{key}" })
            multipart_copy(options, upload_part_options, target_directory_key, target_file_key)
          else
            service.copy_object(directory.key, key, target_directory_key, target_file_key, options)
          end

          target_directory = service.directories.new(:key => target_directory_key)
          target_directory.files.head(target_file_key)
        end

        # Destroy file via http DELETE.
        #
        #     required attributes: directory, key
        #
        # @param options [Hash]
        # @option options versionId []
        # @return [Boolean] true if successful
        #
        def destroy(options = {})
          requires :directory, :key
          attributes[:body] = nil if options['versionId'] == version
          service.delete_object(directory.key, key, options)
          true
        end

        remove_method :metadata
        def metadata
          attributes.reject {|key, value| !(key.to_s =~ /^x-amz-/) }
                    .reject {|key, value| ['x-amz-id-2', 'x-amz-request-id'].include?(key) }
        end

        remove_method :metadata=
        def metadata=(new_metadata)
          merge_attributes(new_metadata)
        end

        remove_method :owner=
        def owner=(new_owner)
          if new_owner
            attributes[:owner] = {
              :display_name => new_owner['DisplayName'] || new_owner[:display_name],
              :id           => new_owner['ID'] || new_owner[:id]
            }
          end
        end

        def public?
          acl.any? {|grant| grant['Grantee']['URI'] == 'http://acs.amazonaws.com/groups/global/AllUsers' && grant['Permission'] == 'READ'}
        end

        # Set Access-Control-List permissions.
        #
        #     valid new_publics: public_read, private
        #
        # @param [String] new_public
        # @return [String] new_public
        #
        def public=(new_public)
          if new_public
            @acl = 'public-read'
          else
            @acl = 'private'
          end
          new_public
        end

        # Get publicly accessible url via http GET.
        # Checks permissions before creating.
        # Defaults to s3 subdomain or compliant bucket name
        #
        #     required attributes: directory, key
        #
        # @return [String] public url
        #
        def public_url
          requires :directory, :key
          if public?
            service.request_url(
              :bucket_name => directory.key,
              :object_name => key
            )
          else
            nil
          end
        end

        # Save file with body as contents to directory.key with name key via http PUT
        #
        #   required attributes: body, directory, key
        #
        # @param [Hash] options
        # @option options [String] acl sets x-amz-acl HTTP header. Valid values include, private | public-read | public-read-write | authenticated-read | bucket-owner-read | bucket-owner-full-control
        # @option options [String] cache_control sets Cache-Control header. For example, 'No-cache'
        # @option options [String] content_disposition sets Content-Disposition HTTP header. For exampple, 'attachment; filename=testing.txt'
        # @option options [String] content_encoding sets Content-Encoding HTTP header. For example, 'x-gzip'
        # @option options [String] content_md5 sets Content-MD5. For example, '79054025255fb1a26e4bc422aef54eb4'
        # @option options [String] content_type Content-Type. For example, 'text/plain'
        # @option options [String] expires sets number of seconds before AWS Object expires.
        # @option options [String] storage_class sets x-amz-storage-class HTTP header. Defaults to 'STANDARD'. Or, 'REDUCED_REDUNDANCY'
        # @option options [String] encryption sets HTTP encryption header. Set to 'AES256' to encrypt files at rest on S3
        # @option options [String] tags sets x-amz-tagging HTTP header. For example, 'Org-Id=1' or 'Org-Id=1&Service=MyService'
        # @option options [String] website_redirect_location sets x-amz-website-redirect-location HTTP header. For example, 'website_redirect_location=http://www.rubydoc.info/github/fog/fog-aws'
        # @return [Boolean] true if no errors
        #
        def save(options = {})
          requires :body, :directory, :key
          if options != {}
            Fog::Logger.deprecation("options param is deprecated, use acl= instead [light_black](#{caller.first})[/]")
          end
          options['x-amz-acl'] ||= @acl if @acl
          options['Cache-Control'] = cache_control if cache_control
          options['Content-Disposition'] = content_disposition if content_disposition
          options['Content-Encoding'] = content_encoding if content_encoding
          options['Content-MD5'] = content_md5 if content_md5
          options['Content-Type'] = content_type if content_type
          options['Expires'] = expires if expires
          options.merge!(metadata)
          options['x-amz-storage-class'] = storage_class if storage_class
          options['x-amz-tagging'] = tags if tags
          options['x-amz-website-redirect-location'] = website_redirect_location if website_redirect_location
          options.merge!(encryption_headers)

          self.multipart_chunk_size = service.max_put_chunk_size if multipart_chunk_size.nil?
          if multipart_chunk_size > 0 && Fog::Storage.get_body_size(body) >= multipart_chunk_size && body.respond_to?(:read)
            data = multipart_save(options)
            merge_attributes(data.body)
          else
            data = service.put_object(directory.key, key, body, options)
            merge_attributes(data.headers.reject {|key, value| ['Content-Length', 'Content-Type'].include?(key)})
          end
          self.etag = self.etag.gsub('"','') if self.etag
          self.content_length = Fog::Storage.get_body_size(body)
          self.content_type ||= Fog::Storage.get_content_type(body)
          true
        end

        # Get a url for file.
        #
        #     required attributes: key
        #
        # @param expires [String] number of seconds (since 1970-01-01 00:00) before url expires
        # @param options [Hash]
        # @return [String] url
        #
        def url(expires, options = {})
          requires :key
          collection.get_url(key, expires, options)
        end

        # File version if exists or creates new version.
        # @return [Fog::AWS::Storage::Version]
        #
        def versions
          @versions ||= begin
            Fog::AWS::Storage::Versions.new(
              :file         => self,
              :service   => service
            )
          end
        end

        private

        def directory=(new_directory)
          @directory = new_directory
        end

        def multipart_save(options)
          # Initiate the upload
          res = service.initiate_multipart_upload(directory.key, key, options)
          upload_id = res.body["UploadId"]

          # Store ETags of upload parts
          part_tags = []

          # Upload each part
          # TODO: optionally upload chunks in parallel using threads
          # (may cause network performance problems with many small chunks)
          # TODO: Support large chunk sizes without reading the chunk into memory
          if body.respond_to?(:rewind)
            body.rewind  rescue nil
          end
          while (chunk = body.read(multipart_chunk_size)) do
            part_upload = service.upload_part(directory.key, key, upload_id, part_tags.size + 1, chunk, part_headers(chunk))
            part_tags << part_upload.headers["ETag"]
          end

          if part_tags.empty? #it is an error to have a multipart upload with no parts
            part_upload = service.upload_part(directory.key, key, upload_id, 1, '', part_headers(''))
            part_tags << part_upload.headers["ETag"]
          end

        rescue
          # Abort the upload & reraise
          service.abort_multipart_upload(directory.key, key, upload_id) if upload_id
          raise
        else
          # Complete the upload
          service.complete_multipart_upload(directory.key, key, upload_id, part_tags)
        end

        def multipart_copy(options, upload_part_options, target_directory_key, target_file_key)
          # Initiate the upload
          res = service.initiate_multipart_upload(target_directory_key, target_file_key, options)
          upload_id = res.body["UploadId"]

          # Store ETags of upload parts
          part_tags = []
          pending = PartList.new(create_part_list(upload_part_options))
          thread_count = self.concurrency
          completed = PartList.new
          errors = upload_in_threads(target_directory_key, target_file_key, upload_id, pending, completed, thread_count)

          raise errors.first if errors.any?

          part_tags = completed.to_a.sort_by { |part| part.part_number }.map(&:etag)
        rescue => e
          # Abort the upload & reraise
          service.abort_multipart_upload(target_directory_key, target_file_key, upload_id) if upload_id
          raise
        else
          # Complete the upload
          service.complete_multipart_upload(target_directory_key, target_file_key, upload_id, part_tags)
        end

        def encryption_headers
          if encryption && encryption_key
            encryption_customer_key_headers
          elsif encryption
            { 'x-amz-server-side-encryption' => encryption, 'x-amz-server-side-encryption-aws-kms-key-id' => kms_key_id }.reject {|_, value| value.nil?}
          else
            {}
          end
        end

        def part_headers(chunk)
          base_headers = part_checksum_headers(chunk)

          # Only SSE-C headers needed in the UploadPart request. [1]
          # x-amz-server-side-encryption and
          # x-amz-server-side-encryption-aws-kms-key-id are only needed
          # in the CreateMultipartUpload request. [2]
          # [1] https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html
          # [2] https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html
          base_headers.merge!(encryption_customer_key_headers) if encryption && encryption_key

          base_headers
        end

        def encryption_customer_key_headers
          {
            'x-amz-server-side-encryption-customer-algorithm' => encryption,
            'x-amz-server-side-encryption-customer-key' => Base64.encode64(encryption_key.to_s).chomp!,
            'x-amz-server-side-encryption-customer-key-md5' => Base64.encode64(OpenSSL::Digest::MD5.digest(encryption_key.to_s)).chomp!
          }
        end

        def part_checksum_headers(chunk)
          if service.disable_content_md5_validation
            {}
          else
            { 'Content-MD5' => Base64.encode64(OpenSSL::Digest::MD5.digest(chunk)).strip }
          end
        end

        def create_part_list(upload_part_options)
          current_pos = 0
          count = 0
          pending = []

          while current_pos < self.content_length do
            start_pos = current_pos
            end_pos = [current_pos + self.multipart_chunk_size, self.content_length - 1].min
            range = "bytes=#{start_pos}-#{end_pos}"
            part_options = upload_part_options.dup
            part_options['x-amz-copy-source-range'] = range
            pending << UploadPartData.new(count + 1, part_options, nil)
            count += 1
            current_pos = end_pos + 1
          end

          pending
        end

        def upload_in_threads(target_directory_key, target_file_key, upload_id, pending, completed, thread_count)
          threads = []

          thread_count.times do
            thread = Thread.new do
              begin
                while part = pending.shift
                  part_upload = service.upload_part_copy(target_directory_key, target_file_key, upload_id, part.part_number, part.upload_options)
                  part.etag = part_upload.body['ETag']
                  completed.push(part)
                end
              rescue => error
                pending.clear!
                error
              end
            end

            thread.abort_on_exception = true
            threads << thread
          end

          threads.map(&:value).compact
        end
      end
    end
  end
end
