# frozen_string_literal: true

module Datadog
  class Statsd
    module Serialization
      class ServiceCheckSerializer
        SERVICE_CHECK_BASIC_OPTIONS = {
          timestamp: 'd:',
          hostname:  'h:',
        }.freeze

        def initialize(global_tags: [])
          @tag_serializer = TagSerializer.new(global_tags)
        end

        def format(name, status, options = EMPTY_OPTIONS)
          String.new.tap do |service_check|
            # line basics
            service_check << "_sc"
            service_check << "|"
            service_check << name.to_s
            service_check << "|"
            service_check << status.to_s

            # we are serializing the generic service check options
            # before serializing specialized options that need edge-cases
            SERVICE_CHECK_BASIC_OPTIONS.each do |option_key, shortcut|
              if value = options[option_key]
                service_check << '|'
                service_check << shortcut
                service_check << value.to_s.delete('|')
              end
            end

            if message = options[:message]
              service_check << '|m:'
              service_check << escape_message(message)
            end

            # also returns the global tags from serializer
            if tags = tag_serializer.format(options[:tags])
              service_check << '|#'
              service_check << tags
            end
          end
        end

        protected
        attr_reader :tag_serializer

        def escape_message(message)
          message.delete('|').tap do |m|
            m.gsub!("\n", '\n')
            m.gsub!('m:', 'm\:')
          end
        end
      end
    end
  end
end
