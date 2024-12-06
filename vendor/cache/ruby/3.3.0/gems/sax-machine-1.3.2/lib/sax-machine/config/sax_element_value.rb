module SAXMachine
  class SAXConfig
    class ElementValueConfig
      attr_reader :name, :setter, :data_class

      def initialize(name, options)
        @name     = name.to_s
        @as       = options[:as]
        @setter   = "#{@as}="
        @required = options[:required]
        @data_class = options[:class]
      end

      def column
        @as || @name.to_sym
      end

      def required?
        !!@required
      end
    end
  end
end
