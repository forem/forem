require 'psych'

module VCR
  class Cassette
    class Serializers
      # The Psych serializer. Psych is the new YAML engine in ruby 1.9.
      #
      # @see JSON
      # @see Syck
      # @see YAML
      module Psych
        extend self
        extend EncodingErrorHandling
        extend SyntaxErrorHandling

        # @private
        ENCODING_ERRORS = [ArgumentError]

        # @private
        SYNTAX_ERRORS = [::Psych::SyntaxError]

        # The file extension to use for this serializer.
        #
        # @return [String] "yml"
        def file_extension
          "yml"
        end

        # Serializes the given hash using Psych.
        #
        # @param [Hash] hash the object to serialize
        # @return [String] the YAML string
        def serialize(hash)
          handle_encoding_errors do
            result = ::Psych.dump(hash)
            result.gsub!(": \n", ": null\n") # set canonical null value in order to avoid trailing whitespaces
            result
          end
        end

        # Deserializes the given string using Psych.
        #
        # @param [String] string the YAML string
        # @return [Hash] the deserialized object
        def deserialize(string)
          handle_encoding_errors do
            handle_syntax_errors do
              ::Psych.load(string)
            end
          end
        end
      end
    end
  end
end

