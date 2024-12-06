module SAXMachine
  class SAXConfig
    class CollectionConfig
      attr_reader :name

      def initialize(name, options)
        @name  = name.to_s
        @class = options[:class]
        @as    = options[:as].to_s
        @with  = options.fetch(:with, {})
      end

      def accessor
        as
      end

      def attrs_match?(attrs)
        @with.all? do |key, value|
          value === attrs[key.to_s]
        end
      end

      def data_class
        @class || @name
      end

      protected
      def as
        @as
      end
    end
  end
end
