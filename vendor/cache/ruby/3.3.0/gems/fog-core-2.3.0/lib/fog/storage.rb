begin
  # Use mime/types/columnar if available, for reduced memory usage
  require 'mime/types/columnar'
rescue LoadError
  require 'mime/types'
end

module Fog
  module Storage
    extend Fog::ServicesMixin

    def self.directories
      directories = []
      providers.each do |provider|
        begin
          directories.concat(self[provider].directories)
        rescue # ignore any missing credentials/etc
        end
      end
      directories
    end

    def self.get_body_size(body)
      if body.respond_to?(:encoding)
        original_encoding = body.encoding
        body = body.dup if body.frozen?
        body = body.force_encoding('BINARY')
      end

      size = if body.respond_to?(:bytesize)
        body.bytesize
      elsif body.respond_to?(:size)
        body.size
      elsif body.respond_to?(:stat)
        body.stat.size
      else
        0
      end

      if body.respond_to?(:encoding)
        body.force_encoding(original_encoding)
      end

      size
    end

    def self.get_content_type(data)
      if data.respond_to?(:path) && !data.path.nil?
        filename = ::File.basename(data.path)
        unless (mime_types = MIME::Types.of(filename)).empty?
          mime_types.first.content_type
        end
      end
    end

    def self.parse_data(data)
      {
        :body     => data,
        :headers  => {
          "Content-Length"  => get_body_size(data),
          "Content-Type"    => get_content_type(data)
          # "Content-MD5" => Base64.encode64(Digest::MD5.digest(metadata[:body])).strip
        }
      }
    end
  end
end
