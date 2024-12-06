module MetaSource
  module Association
    class HasManyMatcher
      attr_reader :name

      def match?(line)
        line =~ /has_many\s+:([a-z_]*)/
        @name = Regexp.last_match(1)

        return unless @name

        if line =~ /class_name:\s+["']([A-Za-z0-9]+)/
          @type = Regexp.last_match(1)
        end

        @name
      end

      def type
        "ActiveRecord::Associations::CollectionProxy<#{@type || name.singularize.camelize}>"
      end
    end
  end
end
