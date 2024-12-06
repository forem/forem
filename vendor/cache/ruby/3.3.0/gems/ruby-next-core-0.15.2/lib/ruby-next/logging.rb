# frozen_string_literal: true

require "ruby-next/utils"

module RubyNext
  class << self
    attr_accessor :silence_warnings
    attr_reader :debug_enabled

    def warn(msg)
      return if silence_warnings

      Kernel.warn msg
    end

    def debug_source(source, filepath = nil)
      return unless debug_enabled

      return if debug_filter && !filepath.include?(debug_filter)

      $stdout.puts Utils.source_with_lines(source, filepath)
    end

    def debug_enabled=(val)
      return if val.nil?

      @debug_enabled = !(val == "false" || val == "0")

      return unless debug_enabled

      return if val == "true" || val == "1"

      @debug_filter = val
    end

    private

    attr_reader :debug_filter
  end

  self.silence_warnings = ENV["RUBY_NEXT_WARN"] == "false"
  self.debug_enabled = ENV["RUBY_NEXT_DEBUG"]
end
