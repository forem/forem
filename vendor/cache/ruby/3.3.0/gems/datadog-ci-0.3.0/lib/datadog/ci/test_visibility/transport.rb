# frozen_string_literal: true

require "msgpack"
require "uri"

require "datadog/core/encoding"
require "datadog/core/environment/identity"
require "datadog/core/chunker"

require_relative "serializers/factories/test_level"
require_relative "../ext/transport"

module Datadog
  module CI
    module TestVisibility
      class Transport
        # CI test cycle intake's limit is 5.1MB uncompressed
        # We will use a bit more conservative value 5MB
        DEFAULT_MAX_PAYLOAD_SIZE = 5 * 1024 * 1024

        attr_reader :serializers_factory,
          :api,
          :max_payload_size,
          :dd_env

        def initialize(
          api:,
          dd_env: nil,
          serializers_factory: Datadog::CI::TestVisibility::Serializers::Factories::TestLevel,
          max_payload_size: DEFAULT_MAX_PAYLOAD_SIZE
        )
          @serializers_factory = serializers_factory
          @max_payload_size = max_payload_size
          @dd_env = dd_env
          @api = api
        end

        def send_traces(traces)
          return [] if traces.nil? || traces.empty?

          Datadog.logger.debug { "Sending #{traces.count} traces..." }

          encoded_events = encode_traces(traces)
          if encoded_events.empty?
            Datadog.logger.debug { "Empty encoded events list, skipping send" }
            return []
          end

          responses = []
          Datadog::Core::Chunker.chunk_by_size(encoded_events, max_payload_size).map do |chunk|
            encoded_payload = pack_events(chunk)
            Datadog.logger.debug do
              "Send chunk of #{chunk.count} events; payload size #{encoded_payload.size}"
            end

            response = send_payload(encoded_payload)

            Datadog.logger.debug do
              "Received server response: #{response.inspect}"
            end

            responses << response
          end

          responses
        end

        private

        def send_payload(encoded_payload)
          api.request(
            path: Datadog::CI::Ext::Transport::TEST_VISIBILITY_INTAKE_PATH,
            payload: encoded_payload
          )
        end

        def encode_traces(traces)
          traces.flat_map do |trace|
            spans = trace.spans
            # TODO: remove condition when 1.0 is released
            if spans.respond_to?(:filter_map)
              spans.filter_map { |span| encode_span(trace, span) }
            else
              trace.spans.map { |span| encode_span(trace, span) }.reject(&:nil?)
            end
          end
        end

        def encode_span(trace, span)
          serializer = serializers_factory.serializer(trace, span)

          if serializer.valid?
            encoded = encoder.encode(serializer)

            if encoded.size > max_payload_size
              # This single event is too large, we can't flush it
              Datadog.logger.debug { "Dropping test event. Payload too large: '#{span.inspect}'" }
              Datadog.logger.debug { encoded }

              return nil
            end

            encoded
          else
            Datadog.logger.debug { "Invalid span skipped: #{span}" }
            nil
          end
        end

        def encoder
          Datadog::Core::Encoding::MsgpackEncoder
        end

        def pack_events(encoded_events)
          packer = MessagePack::Packer.new

          packer.write_map_header(3) # Set header with how many elements in the map

          packer.write("version")
          packer.write(1)

          packer.write("metadata")
          packer.write_map_header(1)

          packer.write("*")
          metadata_fields_count = dd_env ? 4 : 3
          packer.write_map_header(metadata_fields_count)

          if dd_env
            packer.write("env")
            packer.write(dd_env)
          end

          packer.write("runtime-id")
          packer.write(Datadog::Core::Environment::Identity.id)

          packer.write("language")
          packer.write(Datadog::Core::Environment::Identity.lang)

          packer.write("library_version")
          packer.write(Datadog::CI::VERSION::STRING)

          packer.write("events")
          packer.write_array_header(encoded_events.size)

          (packer.buffer.to_a + encoded_events).join
        end
      end
    end
  end
end
