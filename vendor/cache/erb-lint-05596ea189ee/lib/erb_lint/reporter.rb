# frozen_string_literal: true
require 'active_support/core_ext/class'

module ERBLint
  class Reporter
    def self.create_reporter(format, *args)
      reporter_klass = "#{ERBLint::Reporters}::#{format.to_s.camelize}Reporter".constantize
      reporter_klass.new(*args)
    end

    def self.available_format?(format)
      available_formats.include?(format.to_s)
    end

    def self.available_formats
      descendants
        .map(&:to_s)
        .map(&:demodulize)
        .map(&:underscore)
        .map { |klass_name| klass_name.sub("_reporter", "") }
        .sort
    end

    def initialize(stats, autocorrect)
      @stats = stats
      @autocorrect = autocorrect
    end

    def preview; end

    def show; end

    private

    attr_reader :stats, :autocorrect
    delegate :processed_files, to: :stats
  end
end
