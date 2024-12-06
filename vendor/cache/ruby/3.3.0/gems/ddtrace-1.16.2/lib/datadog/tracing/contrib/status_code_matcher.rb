require 'set'

require_relative '../metadata/ext'

module Datadog
  module Tracing
    module Contrib
      # Contains methods helpful for tracing/annotating HTTP request libraries
      class StatusCodeMatcher
        REGEX_PARSER = /^\d{3}(?:-\d{3})?(?:,\d{3}(?:-\d{3})?)*$/.freeze

        def initialize(range)
          @error_response_range = range
          set_range
        end

        def include?(exception_status)
          set_range.include?(exception_status)
        end

        def to_s
          @error_response_range.to_s
        end

        private

        def set_range
          @datadog_set ||= begin
            set = Set.new
            handle_statuses.each do |statuses|
              status = statuses.to_s.split('-')
              case status.length
              when 1
                set.add(Integer(status[0]))
              when 2
                min, max = status.minmax
                Array(min..max).each do |i|
                  set.add(Integer(i))
                end
              end
            end
            set
          end
          @datadog_set
        end

        def error_responses
          return @error_response_range if @error_response_range.is_a?(String) && !@error_response_range.nil?

          @error_response_range.join(',') if @error_response_range.is_a?(Array) && !@error_response_range.empty?
        end

        def handle_statuses
          if error_responses
            filter_error_responses = error_responses.gsub(/\s+/, '').split(',').select do |code|
              if !code.to_s.match(REGEX_PARSER)
                Datadog.logger.debug("Invalid config provided: #{code}. Must be formatted like '400-403,405,410-499'.")
                next
              else
                true
              end
            end
            filter_error_responses.empty? ? Tracing::Metadata::Ext::HTTP::ERROR_RANGE.to_a : filter_error_responses
          else
            Datadog.logger.debug('No valid config was provided for :error_statuses - falling back to default.')
            Tracing::Metadata::Ext::HTTP::ERROR_RANGE.to_a
          end
        end
      end
    end
  end
end
