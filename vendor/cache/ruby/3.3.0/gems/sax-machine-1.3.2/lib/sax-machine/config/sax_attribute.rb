module SAXMachine
  class SAXConfig
    class AttributeConfig < ElementValueConfig
      def value_from_attrs(attrs)
        attrs.fetch(@name, nil)
      end

      def attrs_match?(attrs)
        attrs.key?(@name) || attrs.value?(@name)
      end
      alias_method :has_value_and_attrs_match?, :attrs_match?

      def collection?
        false
      end
    end
  end
end
