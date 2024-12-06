# frozen_string_literal: true

require "erb"

module Brpoplpush
  # Interface to dealing with .lua files
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  module RedisScript
    #
    # Class Template provides LUA script partial template rendering
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    class Template
      def initialize(script_path)
        @script_path = script_path
      end

      #
      # Renders a Lua script and includes any partials in that file
      #  all `<%= include_partial '' %>` replaced with the actual contents of the partial
      #
      # @param [Pathname] pathname the path to the
      #
      # @return [String] the rendered Luascript
      #
      def render(pathname)
        @partial_templates ||= {}
        ::ERB.new(File.read(pathname)).result(binding)
      end

      # helper method to include a lua partial within another lua script
      #
      def include_partial(relative_path)
        return if @partial_templates.key?(relative_path)

        @partial_templates[relative_path] = nil
        render(Pathname.new("#{@script_path}/#{relative_path}"))
      end
    end
  end
end
