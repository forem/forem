# frozen_string_literal: true

module Capybara
  # @api private
  module Queries
    class BaseQuery
      COUNT_KEYS = %i[count minimum maximum between].freeze

      attr_reader :options
      attr_writer :session_options

      def initialize(options)
        @session_options = options.delete(:session_options)
      end

      def session_options
        @session_options || Capybara.session_options
      end

      def wait
        self.class.wait(options, session_options.default_max_wait_time)
      end

      def self.wait(options, default = Capybara.default_max_wait_time)
        # if no value or nil for the :wait option is passed it should default to the default
        wait = options.fetch(:wait, nil)
        wait = default if wait.nil?
        wait || 0
      end

      ##
      #
      # Checks if a count of 0 is valid for the query
      # Returns false if query does not have any count options specified.
      #
      def expects_none?
        count_specified? ? matches_count?(0) : false
      end

      ##
      #
      # Checks if the given count matches the query count options.
      # Defaults to true if no count options are specified. If multiple
      # count options exist, it tests that all conditions are met;
      # however, if :count is specified, all other options are ignored.
      #
      # @param [Integer] count     The actual number. Should be coercible via Integer()
      #
      def matches_count?(count)
        return (Integer(options[:count]) == count) if options[:count]
        return false if options[:maximum] && (Integer(options[:maximum]) < count)
        return false if options[:minimum] && (Integer(options[:minimum]) > count)
        return false if options[:between] && !options[:between].include?(count)

        true
      end

      ##
      #
      # Generates a failure message from the query description and count options.
      #
      def failure_message
        +"expected to find #{description}" << count_message
      end

      def negative_failure_message
        +"expected not to find #{description}" << count_message
      end

    private

      def count_specified?
        COUNT_KEYS.any? { |key| options.key? key }
      end

      def count_message
        message = +''
        count, between, maximum, minimum = options.values_at(:count, :between, :maximum, :minimum)
        if count
          message << " #{occurrences count}"
        elsif between
          message << " between #{between.begin ? between.first : 1} and" \
                     " #{between.end ? between.last : 'infinite'} times"
        elsif maximum
          message << " at most #{occurrences maximum}"
        elsif minimum
          message << " at least #{occurrences minimum}"
        end
        message
      end

      def occurrences(count)
        "#{count} #{Capybara::Helpers.declension('time', 'times', count)}"
      end

      def assert_valid_keys
        invalid_keys = @options.keys - valid_keys
        return if invalid_keys.empty?

        invalid_names = invalid_keys.map(&:inspect).join(', ')
        valid_names = valid_keys.map(&:inspect).join(', ')
        raise ArgumentError, "Invalid option(s) #{invalid_names}, should be one of #{valid_names}"
      end
    end
  end
end
