module VCR
  class Cassette
    # Keeps track of the cassette persisters in a hash-like object.
    class Persisters
      autoload :FileSystem, 'vcr/cassette/persisters/file_system'

      # @private
      def initialize
        @persisters = {}
      end

      # Gets the named persister.
      #
      # @param name [Symbol] the name of the persister
      # @return the named persister
      # @raise [ArgumentError] if there is not a persister for the given name
      def [](name)
        @persisters.fetch(name) do |_|
          @persisters[name] = case name
            when :file_system then FileSystem
            else raise ArgumentError, "The requested VCR cassette persister " +
                                      "(#{name.inspect}) is not registered."
          end
        end
      end

      # Registers a persister.
      #
      # @param name [Symbol] the name of the persister
      # @param value [#[], #[]=] the persister object. It must implement `[]` and `[]=`.
      def []=(name, value)
        if @persisters.has_key?(name)
          warn "WARNING: There is already a VCR cassette persister " +
               "registered for #{name.inspect}. Overriding it."
        end

        @persisters[name] = value
      end

    end
  end
end
