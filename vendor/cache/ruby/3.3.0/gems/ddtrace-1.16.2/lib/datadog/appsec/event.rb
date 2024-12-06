require 'json'
require 'zlib'
require 'base64'

require_relative 'rate_limiter'

module Datadog
  module AppSec
    # AppSec event
    module Event
      ALLOWED_REQUEST_HEADERS = %w[
        X-Forwarded-For
        X-Client-IP
        X-Real-IP
        X-Forwarded
        X-Cluster-Client-IP
        Forwarded-For
        Forwarded
        Via
        True-Client-IP
        Content-Length
        Content-Type
        Content-Encoding
        Content-Language
        Host
        User-Agent
        Accept
        Accept-Encoding
        Accept-Language
      ].map!(&:downcase).freeze

      ALLOWED_RESPONSE_HEADERS = %w[
        Content-Length
        Content-Type
        Content-Encoding
        Content-Language
      ].map!(&:downcase).freeze

      MAX_ENCODED_SCHEMA_SIZE = 25000
      # For more information about this number
      # please check https://github.com/DataDog/dd-trace-rb/pull/3177#issuecomment-1747221082
      MIN_SCHEMA_SIZE_FOR_COMPRESSION = 260

      # Record events for a trace
      #
      # This is expected to be called only once per trace for the rate limiter
      # to properly apply
      class << self
        def record(span, *events)
          # ensure rate limiter is called only when there are events to record
          return if events.empty? || span.nil?

          Datadog::AppSec::RateLimiter.limit(:traces) do
            record_via_span(span, *events)
          end
        end

        def record_via_span(span, *events)
          events.group_by { |e| e[:trace] }.each do |trace, event_group|
            unless trace
              Datadog.logger.debug { "{ error: 'no trace: cannot record', event_group: #{event_group.inspect}}" }
              next
            end

            trace.keep!
            trace.set_tag(
              Datadog::Tracing::Metadata::Ext::Distributed::TAG_DECISION_MAKER,
              Datadog::Tracing::Sampling::Ext::Decision::ASM
            )

            # prepare and gather tags to apply
            service_entry_tags = build_service_entry_tags(event_group)

            # apply tags to service entry span
            service_entry_tags.each do |key, value|
              span.set_tag(key, value)
            end
          end
        end

        # rubocop:disable Metrics/MethodLength
        def build_service_entry_tags(event_group)
          waf_events = []
          entry_tags = event_group.each_with_object({ '_dd.origin' => 'appsec' }) do |event, tags|
            # TODO: assume HTTP request context for now
            if (request = event[:request])
              request.headers.each do |header, value|
                tags["http.request.headers.#{header}"] = value if ALLOWED_REQUEST_HEADERS.include?(header.downcase)
              end

              tags['http.host'] = request.host
              tags['http.useragent'] = request.user_agent
              tags['network.client.ip'] = request.remote_addr
            end

            if (response = event[:response])
              response.headers.each do |header, value|
                tags["http.response.headers.#{header}"] = value if ALLOWED_RESPONSE_HEADERS.include?(header.downcase)
              end
            end

            waf_result = event[:waf_result]
            # accumulate triggers
            waf_events += waf_result.events

            waf_result.derivatives.each do |key, value|
              parsed_value = json_parse(value)
              next unless parsed_value

              parsed_value_size = parsed_value.size

              schema_value = if parsed_value_size >= MIN_SCHEMA_SIZE_FOR_COMPRESSION
                               compressed_and_base64_encoded(parsed_value)
                             else
                               parsed_value
                             end
              next unless schema_value

              if schema_value.size >= MAX_ENCODED_SCHEMA_SIZE
                Datadog.logger.debug do
                  "Schema key: #{key} exceeds the max size value. It will not be included as part of the span tags"
                end
                next
              end

              tags[key] = schema_value
            end

            tags
          end

          appsec_events = json_parse({ triggers: waf_events })
          entry_tags['_dd.appsec.json'] = appsec_events if appsec_events
          entry_tags
        end
        # rubocop:enable Metrics/MethodLength

        private

        def compressed_and_base64_encoded(value)
          Base64.encode64(gzip(value))
        rescue TypeError => e
          Datadog.logger.debug do
            "Failed to compress and encode value when populating AppSec::Event. Error: #{e.message}"
          end
          nil
        end

        def json_parse(value)
          JSON.dump(value)
        rescue ArgumentError => e
          Datadog.logger.debug do
            "Failed to parse value to JSON when populating AppSec::Event. Error: #{e.message}"
          end
          nil
        end

        def gzip(value)
          sio = StringIO.new
          # For an in depth comparison of Zlib options check https://github.com/DataDog/dd-trace-rb/pull/3177#issuecomment-1747215473
          gz = Zlib::GzipWriter.new(sio, Zlib::BEST_SPEED, Zlib::DEFAULT_STRATEGY)
          gz.write(value)
          gz.close
          sio.string
        end
      end
    end
  end
end
