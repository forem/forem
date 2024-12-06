require 'zlib'
require 'vcr/cassette/serializers'

module VCR
  class Cassette
    class Serializers
      # The compressed serializer. This serializer wraps the YAML serializer
      # to write compressed cassettes to disk.
      #
      # Cassettes containing responses with JSON data often compress at greater
      # than 10:1. The tradeoff is that cassettes will not diff nicely or be
      # easily inspectable or editable.
      #
      # @see YAML
      module Compressed
        extend self

        # The file extension to use for this serializer.
        #
        # @return [String] "zz"
        def file_extension
          'zz'
        end

        # Serializes the given hash using YAML and Zlib.
        #
        # @param [Hash] hash the object to serialize
        # @return [String] the compressed cassette data
        def serialize(hash)
          string = VCR::Cassette::Serializers::YAML.serialize(hash)
          Zlib::Deflate.deflate(string)
        end

        # Deserializes the given compressed cassette data.
        #
        # @param [String] string the compressed YAML cassette data
        # @return [Hash] the deserialized object
        def deserialize(string)
          yaml = Zlib::Inflate.inflate(string)
          VCR::Cassette::Serializers::YAML.deserialize(yaml)
        end
      end
    end
  end
end
