# frozen_string_literal: true

module Capybara
  # @api private
  module Helpers
  module_function

    ##
    # @deprecated
    # Normalizes whitespace space by stripping leading and trailing
    # whitespace and replacing sequences of whitespace characters
    # with a single space.
    #
    # @param [String] text     Text to normalize
    # @return [String]         Normalized text
    #
    def normalize_whitespace(text)
      Capybara::Helpers.warn 'DEPRECATED: Capybara::Helpers::normalize_whitespace is deprecated, please update your driver'
      text.to_s.gsub(/[[:space:]]+/, ' ').strip
    end

    ##
    #
    # Escapes any characters that would have special meaning in a regexp
    # if text is not a regexp
    #
    # @param [String] text Text to escape
    # @param [Boolean] exact (false) Whether or not this should be an exact text match
    # @param [Fixnum, Boolean, nil] options Options passed to Regexp.new when creating the Regexp
    # @return [Regexp] Regexp to match the passed in text and options
    #
    def to_regexp(text, exact: false, all_whitespace: false, options: nil)
      return text if text.is_a?(Regexp)

      escaped = Regexp.escape(text)
      escaped = escaped.gsub('\\ ', '[[:blank:]]') if all_whitespace
      escaped = "\\A#{escaped}\\z" if exact
      Regexp.new(escaped, options)
    end

    ##
    #
    # Injects a `<base>` tag into the given HTML code, pointing to
    # {Capybara.configure asset_host}.
    #
    # @param [String] html     HTML code to inject into
    # @param [URL] host (Capybara.asset_host) The host from which assets should be loaded
    # @return [String]         The modified HTML code
    #
    def inject_asset_host(html, host: Capybara.asset_host)
      if host && Nokogiri::HTML(html).css('base').empty?
        html.match(/<head[^<]*?>/) do |m|
          return html.clone.insert m.end(0), "<base href='#{host}' />"
        end
      end
      html
    end

    ##
    #
    # A poor man's `pluralize`. Given two declensions, one singular and one
    # plural, as well as a count, this will pick the correct declension. This
    # way we can generate grammatically correct error message.
    #
    # @param [String] singular     The singular form of the word
    # @param [String] plural       The plural form of the word
    # @param [Integer] count       The number of items
    #
    def declension(singular, plural, count)
      count == 1 ? singular : plural
    end

    def filter_backtrace(trace)
      return 'No backtrace' unless trace

      filter = %r{lib/capybara/|lib/rspec/|lib/minitest/|delegate.rb}
      new_trace = trace.take_while { |line| line !~ filter }
      new_trace = trace.grep_v(filter) if new_trace.empty?
      new_trace = trace.dup if new_trace.empty?

      new_trace.first.split(/:in /, 2).first
    end

    def warn(message, uplevel: 1)
      Kernel.warn(message, uplevel: uplevel)
    end

    if defined?(Process::CLOCK_MONOTONIC)
      def monotonic_time; Process.clock_gettime Process::CLOCK_MONOTONIC; end
    else
      def monotonic_time; Time.now.to_f; end
    end

    def timer(expire_in:)
      Timer.new(expire_in)
    end

    class Timer
      def initialize(expire_in)
        @start = current
        @expire_in = expire_in
      end

      def expired?
        if stalled?
          raise Capybara::FrozenInTime, 'Time appears to be frozen. Capybara does not work with libraries which freeze time, consider using time travelling instead'
        end

        current - @start >= @expire_in
      end

      def stalled?
        @start == current
      end

    private

      def current
        Capybara::Helpers.monotonic_time
      end
    end
  end
end
