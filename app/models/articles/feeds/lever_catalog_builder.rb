module Articles
  module Feeds
    # This class is responsible for publishing/registering the available relevancy and order levers.
    class LeverCatalogBuilder
      # Raised when we have a key uniqueness violation.
      class DuplicateLeverError < StandardError
        def initialize(klass:, key:)
          super("A duplicate #{klass} entry was attempted for #{key.inspect}.  These must be unique.")
        end
      end

      # @yieldparam [Articles::Feeds::LeverCatalogBuilder]
      #
      # @raise [Articles::Feeds::LeverCatalogBuilder::DuplicateLeverError] when you attempt to
      #        register a lever with the same key.
      #
      # @note Once initialized, this object and its constituent parts are frozen to prevent further
      #       modification.  In other words, once instantiated our published catalog has been
      #       printed and we can't change it.
      def initialize(&config)
        @relevancy_levers = {}
        @order_by_levers = {}

        # In order to call the protected methods at instantiation time, we need to use the
        # `#instance_exec` method.
        instance_exec(&config)

        @relevancy_levers.freeze
        @order_by_levers.freeze
        freeze
      end

      # @param key [#to_sym]
      # @return [Articles::Feeds::RelevancyLever]
      #
      # @raise [KeyError] if the given key is not found in the list of relevancy levers; in other
      #        words we have a configuration mismatch.
      def fetch_lever(key)
        @relevancy_levers.fetch(key.to_sym)
      end

      # @param key [#to_sym]
      # @return [Articles::Feeds::OrderByLever]
      #
      # @raise [KeyError] if the given key is not found in the list of sort levers; in other words
      #        we have a configuration mismatch.
      def fetch_order_by(key)
        @order_by_levers.fetch(key.to_sym)
      end

      protected

      # This is a protected method because after instantiation, we don't want folks fiddling with
      # our published catalog.
      def relevancy_lever(key, **kwargs)
        lever = RelevancyLever.new(key: key, **kwargs).freeze

        raise DuplicateLeverError.new(klass: lever.class, key: lever.key) if @relevancy_levers.key?(lever.key)

        @relevancy_levers[lever.key] = lever
      end

      # This is a protected method because after instantiation, we don't want folks fiddling with
      # our published catalog.
      def order_by_lever(key, **kwargs)
        lever = OrderByLever.new(key: key, **kwargs).freeze

        raise DuplicateLeverError.new(klass: lever.class, key: lever.key) if @order_by_levers.key?(lever.key)

        @order_by_levers[lever.key] = lever
      end
    end
  end
end
