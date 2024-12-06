require 'active_storage/blob_key'
require 'cloudinary/helper'
require 'net/http'

unless ActiveStorage::Blob.method_defined? :original_key
  class ActiveStorage::Blob
    alias_method :original_key, :key

    def key
      original_key
      ActiveStorage::BlobKey.new(@attributes.as_json)
    end
  end
end

module CloudinaryHelper
  alias cloudinary_url_internal_original cloudinary_url_internal

  def cloudinary_url_internal(source, options = {})
    source = ActiveStorage::Blob.service.public_id(source) if defined? ActiveStorage::Blob.service.public_id
    cloudinary_url_internal_original(source, options)
  end
end

module ActiveStorage
  class Service::CloudinaryService < Service
    module Headers
      CONTENT_TYPE = "Content-Type".freeze
      CONTENT_MD5 = "Content-MD5".freeze
    end
    attr_reader :upload_options

    def initialize(**options)
      @options = options
    end

    def upload(key, io, filename: nil, checksum: nil, **options)
      instrument :upload, key: key, checksum: checksum do
        begin
          extra_headers = checksum.nil? ? {} : {Headers::CONTENT_MD5 => checksum}
          options = @options.merge(options)
          Cloudinary::Uploader.upload_large(
            io,
            public_id: public_id_internal(key),
            resource_type: resource_type(io, key),
            context: {active_storage_key: key, checksum: checksum},
            extra_headers: extra_headers,
            **options
          )
        rescue CloudinaryException => e
          raise ActiveStorage::IntegrityError, e.message, e.backtrace
        end
      end
    end

    def url(key, filename: nil, content_type: '', **options)
      instrument :url, key: key do |payload|
        url = Cloudinary::Utils.cloudinary_url(
          full_public_id_internal(key),
          resource_type: resource_type(nil, key, content_type),
          format: ext_for_file(key, filename, content_type),
          **@options.merge(options.symbolize_keys)
        )

        payload[:url] = url

        url
      end
    end

    def url_for_direct_upload(key, **options)
      instrument :url, key: key do |payload|
        options = @options.merge(options.symbolize_keys)
        options[:resource_type] ||= resource_type(nil, key, options[:content_type])
        options[:public_id] = public_id_internal(key)
        # Provide file format for raw files, since js client does not include original file name.
        #
        # When the file is uploaded from the server, the request includes original filename. That allows Cloudinary
        # to identify file extension and append it to the public id of the file (raw files include file extension
        # in their public id, opposed to transformable assets (images/video) that use only basename). When uploading
        # through direct upload (client side js), filename is missing, and that leads to inconsistent/broken URLs.
        # To avoid that, we explicitly pass file format in options.
        options[:format] = ext_for_file(key) if options[:resource_type] == "raw"
        context = options.delete(:context)
        options[:context] = {active_storage_key: key}
        options[:context].reverse_merge!(context) if context.respond_to?(:merge)
        options.delete(:file)
        payload[:url] = api_uri("upload", options)
      end
    end

    def headers_for_direct_upload(key, content_type:, checksum:, **)
      {
        Headers::CONTENT_TYPE => content_type,
        Headers::CONTENT_MD5 => checksum,
      }
    end

    def delete(key)
      instrument :delete, key: key do
        options = {
          resource_type: resource_type(nil, key),
          type: @options[:type]
        }.compact

        Cloudinary::Uploader.destroy public_id(key), **options
      end
    end

    def delete_prefixed(prefix)
      # This method is used by ActiveStorage to delete derived resources after the main resource was deleted.
      # In Cloudinary, the derived resources are deleted automatically when the main resource is deleted.
    end

    def exist?(key)
      instrument :exist, key: key do |payload|
        begin
          options = {
            resource_type: resource_type(nil, key),
            type: @options[:type]
          }.compact

          Cloudinary::Api.resource public_id(key), **options
          true
        rescue Cloudinary::Api::NotFound => e
          false
        end
      end
    end

    def download(key, &block)
      uri = URI(url(key))
      if block_given?
        instrument :streaming_download, key: key do
          Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
            request = Net::HTTP::Get.new uri
            http.request request do |response|
              response.read_body &block
            end
          end
        end
      else
        instrument :download, key: key do
          res = Net::HTTP::get_response(uri)
          res.body
        end
      end
    end

    # Return the partial content in the byte +range+ of the file at the +key+.
    def download_chunk(key, range)
      url = Cloudinary::Utils.unsigned_download_url(public_id(key), resource_type: resource_type(nil, key))
      uri = URI(url)
      instrument :download, key: key do
        req = Net::HTTP::Get.new(uri)
        range_end = case
                    when range.end.nil? then ''
                    when range.exclude_end? then range.end - 1
                    else range.end
                    end
        req['range'] = "bytes=#{[range.begin, range_end].join('-')}"
        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(req)
        end
        res.body.force_encoding(Encoding::BINARY)
      end

    end

    # Returns the public id of the asset.
    #
    # Public id includes both folder(defined globally in the configuration) and the active storage key.
    # For raw files it also includes the file extension, since that's how Cloudinary stores raw files.
    #
    # @param [ActiveStorage::BlobKey]   key          The blob key with attributes.
    # @param [ActiveStorage::Filename]  filename     The original filename.
    # @param [string]                   content_type The content type of the file.
    #
    # @return [string] The public id of the asset.
    def public_id(key, filename = nil, content_type = '')
      public_id = key
      if resource_type(nil, key) == 'raw'
        public_id = [key, ext_for_file(key, filename, content_type)].reject(&:blank?).join('.')
      end

      full_public_id_internal(public_id)
    end

    private

    def api_uri(action, options)
      base_url = Cloudinary::Utils.cloudinary_api_url(action, options)
      upload_params = Cloudinary::Uploader.build_upload_params(options)

      upload_params.reject! { |k, v| Cloudinary::Utils.safe_blank?(v) }
      unless options[:unsigned]
        upload_params = Cloudinary::Utils.sign_request(upload_params, options)
      end
      "#{base_url}?#{upload_params.to_query}"
    end

    # Helper method for getting the filename extension.
    #
    # It does the best effort when original filename does not include extension, but we know the mime-type.
    #
    # @param [ActiveStorage::BlobKey]   key          The blob key with attributes.
    # @param [ActiveStorage::Filename]  filename     The original filename.
    # @param [string]                   content_type The content type of the file.
    #
    # @return [string] The extension of the filename.
    def ext_for_file(key, filename = nil, content_type = nil)
      if filename.blank?
        options = key.respond_to?(:attributes) ? key.attributes : {}
        filename = ActiveStorage::Filename.new(options[:filename]) if options.has_key?(:filename)
      end
      ext = filename.respond_to?(:extension_without_delimiter) ? filename.extension_without_delimiter : nil

      return ext unless ext.blank?

      # Raw files are not convertible, no extension guessing for them
      return nil if content_type_to_resource_type(content_type).eql?('raw')

      # Fallback when there is no extension.
      @formats ||= Hash.new do |h, key|
        ext = Rack::Mime::MIME_TYPES.invert[key]
        h[key] = ext.slice(1..-1) unless ext.nil?
      end
      @formats[content_type]
    end

    # Returns the full public id including folder.
    def full_public_id_internal(key)
      public_id = public_id_internal(key)

      return public_id unless @options[:folder]

      File.join(@options.fetch(:folder), public_id)
    end

    def public_id_internal(key)
      # TODO: Allow custom manipulation of key to obscure how we store in Cloudinary
      key
    end

    def content_type_to_resource_type(content_type)
      return 'image' if content_type.nil?

      type, subtype = content_type.split('/')
      case type
      when 'video', 'audio'
        'video'
      when 'text'
        'raw'
      when 'application'
        case subtype
        when 'pdf', 'postscript'
          'image'
        when 'vnd.apple.mpegurl', 'x-mpegurl', 'mpegurl' # m3u8
          'video'
        else
          'raw'
        end
      else
        'image'
      end
    end

    def resource_type(io, key = "", content_type = "")
      if content_type.blank?
        options = key.respond_to?(:attributes) ? key.attributes : {}
        content_type = options[:content_type] || (io.nil? ? '' : Marcel::MimeType.for(io))
      end
      content_type_to_resource_type(content_type)
    end
  end
end
