module MetaSource
  module Association
    class HasOneMatcher
      attr_reader :name

      def match?(line)
        line =~ /has_one\s+:([a-z_]*)/
        @name = Regexp.last_match(1)

        return unless @name

        if line =~ /class_name:\s+["']([A-Za-z0-9]+)/
          @type = Regexp.last_match(1)
        end

        @name
      end

      def type
        @type || name.camelize
      end
    end
  end
end
