require "guard/plugin_util"
require "guard/group"
require "guard/plugin"

module Guard
  # @private api
  module Internals
    class Plugins
      def initialize
        @plugins = []
      end

      def all(filter = nil)
        return @plugins if filter.nil?
        matcher = matcher_for(filter)
        @plugins.select { |plugin| matcher.call(plugin) }
      end

      def remove(plugin)
        @plugins.delete(plugin)
      end

      # TODO: should it allow duplicates? (probably yes because of different
      # configs or groups)
      def add(name, options)
        @plugins << PluginUtil.new(name).initialize_plugin(options)
      end

      private

      def matcher_for(filter)
        case filter
        when String, Symbol
          shortname = filter.to_s.downcase.delete("-")
          ->(plugin) { plugin.name == shortname }
        when Regexp
          ->(plugin) { plugin.name =~ filter }
        when Hash
          lambda do |plugin|
            filter.all? do |k, v|
              case k
              when :name
                plugin.name == v.to_s.downcase.delete("-")
              when :group
                plugin.group.name == v.to_sym
              end
            end
          end
        end
      end
    end
  end
end
