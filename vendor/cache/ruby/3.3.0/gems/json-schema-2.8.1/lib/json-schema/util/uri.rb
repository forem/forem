require 'addressable/uri'

module JSON
  module Util
    module URI
      SUPPORTED_PROTOCOLS = %w(http https ftp tftp sftp ssh svn+ssh telnet nntp gopher wais ldap prospero)

      def self.normalized_uri(uri, base_path = Dir.pwd)
        @normalize_cache ||= {}
        normalized_uri = @normalize_cache[uri]

        if !normalized_uri
          normalized_uri = parse(uri)
          # Check for absolute path
          if normalized_uri.relative?
            data = normalized_uri
            data = File.join(base_path, data) if data.path[0,1] != "/"
            normalized_uri = file_uri(data)
          end
          @normalize_cache[uri] = normalized_uri.freeze
        end

        normalized_uri
      end

      def self.absolutize_ref(ref, base)
        ref_uri = strip_fragment(ref.dup)

        return ref_uri if ref_uri.absolute?
        return parse(base) if ref_uri.path.empty?

        uri = strip_fragment(base.dup).join(ref_uri.path)
        normalized_uri(uri)
      end

      def self.normalize_ref(ref, base)
        ref_uri = parse(ref)
        base_uri = parse(base)

        ref_uri.defer_validation do
          if ref_uri.relative?
            ref_uri.merge!(base_uri)

            # Check for absolute path
            path, fragment = ref.to_s.split("#")
            if path.nil? || path == ''
              ref_uri.path = base_uri.path
            elsif path[0,1] == "/"
              ref_uri.path = Pathname.new(path).cleanpath.to_s
            else
              ref_uri.join!(path)
            end

            ref_uri.fragment = fragment
          end

          ref_uri.fragment = "" if ref_uri.fragment.nil? || ref_uri.fragment.empty?
        end

        ref_uri
      end

      def self.parse(uri)
        if uri.is_a?(Addressable::URI)
          return uri.dup
        else
          @parse_cache ||= {}
          parsed_uri = @parse_cache[uri]
          if parsed_uri
            parsed_uri.dup
          else
            @parse_cache[uri] = Addressable::URI.parse(uri)
          end
        end
      rescue Addressable::URI::InvalidURIError => e
        raise JSON::Schema::UriError.new(e.message)
      end

      def self.strip_fragment(uri)
        parsed_uri = parse(uri)
        if parsed_uri.fragment.nil? || parsed_uri.fragment.empty?
          parsed_uri
        else
          parsed_uri.merge(:fragment => "")
        end
      end

      def self.file_uri(uri)
        parsed_uri = parse(uri)

        Addressable::URI.convert_path(parsed_uri.path)
      end

      def self.unescape_uri(uri)
        Addressable::URI.unescape(uri)
      end

      def self.unescaped_path(uri)
        parsed_uri = parse(uri)

        Addressable::URI.unescape(parsed_uri.path)
      end

      def self.clear_cache
        @parse_cache = {}
        @normalize_cache = {}
      end
    end
  end
end
