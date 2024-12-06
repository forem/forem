module Cloudinary::CarrierWave
  def download!(uri, *args)
    return super unless self.cloudinary_should_handle_remote?
    if respond_to?(:process_uri)
      uri = process_uri(uri)
    else # Backward compatibility with old CarrierWave
      remote_url_unsafe_chars = /([^a-zA-Z0-9_.\-\/:?&=]+)/ # In addition allow query string characters: "?","&" and "="
      uri = URI.parse(Cloudinary::Utils.smart_escape(Cloudinary::Utils.smart_unescape(uri), remote_url_unsafe_chars))
    end
    return if uri.to_s.blank?
    self.original_filename = @cache_id = @filename = File.basename(uri.path).gsub(/[^a-zA-Z0-9\.\-\+_]/, '')
    @file = RemoteFile.new(uri, @filename)
  end

  class RemoteFile
    attr_reader :uri, :original_filename
    def initialize(uri, filename)
      @uri = uri
      @original_filename = filename
    end

    def delete
      # Do nothing. This is a virtual file.
    end
  end
end
