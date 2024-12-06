# frozen_string_literal: true

module Solargraph
  class Source
    module EncodingFixes
      module_function

      # Convert strings to normalized UTF-8.
      #
      # @param string [String]
      # @return [String]
      def normalize string
        begin
          string.dup.force_encoding('UTF-8')
        rescue ::Encoding::CompatibilityError, ::Encoding::UndefinedConversionError, ::Encoding::InvalidByteSequenceError => e
          # @todo Improve error handling
          Solargraph::Logging.logger.warn "Normalize error: #{e.message}"
          string
        end
      end
    end
  end
end
