module VCR
  class Cassette
    # Keeps track of the cassette serializers in a hash-like object.
    class Serializers
      autoload :YAML,       'vcr/cassette/serializers/yaml'
      autoload :Syck,       'vcr/cassette/serializers/syck'
      autoload :Psych,      'vcr/cassette/serializers/psych'
      autoload :JSON,       'vcr/cassette/serializers/json'
      autoload :Compressed, 'vcr/cassette/serializers/compressed'

      # @private
      def initialize
        @serializers = {}
      end

      # Gets the named serializer.
      #
      # @param name [Symbol] the name of the serializer
      # @return the named serializer
      # @raise [ArgumentError] if there is not a serializer for the given name
      def [](name)
        @serializers.fetch(name) do |_|
          @serializers[name] = case name
            when :yaml        then YAML
            when :syck        then Syck
            when :psych       then Psych
            when :json        then JSON
            when :compressed  then Compressed
            else raise ArgumentError.new("The requested VCR cassette serializer (#{name.inspect}) is not registered.")
          end
        end
      end

      # Registers a serializer.
      #
      # @param name [Symbol] the name of the serializer
      # @param value [#file_extension, #serialize, #deserialize] the serializer object. It must implement
      #  `file_extension()`, `serialize(Hash)` and `deserialize(String)`.
      def []=(name, value)
        if @serializers.has_key?(name)
          warn "WARNING: There is already a VCR cassette serializer registered for #{name.inspect}. Overriding it."
        end

        @serializers[name] = value
      end
    end

    # @private
    module EncodingErrorHandling
      def handle_encoding_errors
        yield
      rescue *self::ENCODING_ERRORS => e
        e.message << "\nNote: Using VCR's `:preserve_exact_body_bytes` option may help prevent this error in the future."
        raise
      end
    end

    # @private
    module SyntaxErrorHandling
      def handle_syntax_errors
        yield
      rescue *self::SYNTAX_ERRORS => e
        e.message << "\nNote: This is a VCR cassette. If it is using ERB, you may have forgotten to pass the `:erb` option to `use_cassette`."
        raise
      end
    end
  end
end

