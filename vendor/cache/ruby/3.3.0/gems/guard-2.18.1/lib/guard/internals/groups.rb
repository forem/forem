require "guard/group"

module Guard
  # @private api
  module Internals
    class Groups
      DEFAULT_GROUPS = [:common, :default]

      def initialize
        @groups = DEFAULT_GROUPS.map { |name| Group.new(name) }
      end

      def all(filter = nil)
        return @groups if filter.nil?
        matcher = matcher_for(filter)
        @groups.select { |group| matcher.call(group) }
      end

      def add(name, options = {})
        all(name).first || Group.new(name, options).tap do |group|
          fail if name == :specs && options.empty?
          @groups << group
        end
      end

      private

      def matcher_for(filter)
        case filter
        when String, Symbol
          ->(group) { group.name == filter.to_sym }
        when Regexp
          ->(group) { group.name.to_s =~ filter }
        else
          fail "Invalid filter: #{filter.inspect}"
        end
      end
    end
  end
end
