# frozen_string_literal: true

module Rouge
  module Guessers
    module Util
      module SourceNormalizer
        UTF8_BOM = "\xEF\xBB\xBF"
        UTF8_BOM_RE = /\A#{UTF8_BOM}/

        # @param [String,nil] source
        # @return [String,nil]
        def self.normalize(source)
          source.sub(UTF8_BOM_RE, '').gsub(/\r\n/, "\n")
        end
      end

      def test_glob(pattern, path)
        File.fnmatch?(pattern, path, File::FNM_DOTMATCH | File::FNM_CASEFOLD)
      end

      # @param [String,IO] source
      # @return [String]
      def get_source(source)
        if source.respond_to?(:to_str)
          SourceNormalizer.normalize(source.to_str)
        elsif source.respond_to?(:read)
          SourceNormalizer.normalize(source.read)
        else
          raise ArgumentError, "Invalid source: #{source.inspect}"
        end
      end
    end
  end
end
