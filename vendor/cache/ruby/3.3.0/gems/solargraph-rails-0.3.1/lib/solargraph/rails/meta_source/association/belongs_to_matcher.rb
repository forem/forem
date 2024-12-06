module MetaSource
  module Association
    class BelongsToMatcher
      attr_reader :name

      def match?(line)
        line =~ /belongs_to\s+:([a-z_]*)/
        @name = Regexp.last_match(1)

        return unless @name

        return @name unless line =~ /class_name:\s+["']([A-Za-z0-9]+)/

        @type = Regexp.last_match(1)

        @name
      end

      def type
        @type || name&.camelize
      end
    end
  end
end
