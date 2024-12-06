# frozen_string_literal: true

require 'json'

module Solargraph
  module LanguageServer
    module Transport
      class DataReader
        def initialize
          @in_header = true
          @content_length = 0
          @buffer = String.new
        end

        # Declare a block to be executed for each message received from the
        # client.
        #
        # @yieldparam [Hash] The message received from the client
        def set_message_handler &block
          @message_handler = block
        end

        # Process raw data received from the client. The data will be parsed
        # into messages based on the JSON-RPC protocol. Each message will be
        # passed to the block declared via set_message_handler. Incomplete data
        # will be buffered and subsequent data will be appended to the buffer.
        #
        # @param data [String]
        def receive data
          data.each_char do |char|
            @buffer.concat char
            if @in_header
              prepare_to_parse_message if @buffer.end_with?("\r\n\r\n")
            else
              parse_message_from_buffer if @buffer.bytesize == @content_length
            end
          end
        end

        private

        # @return [void]
        def prepare_to_parse_message
          @in_header = false
          @buffer.each_line do |line|
            parts = line.split(':').map(&:strip)
            if parts[0] == 'Content-Length'
              @content_length = parts[1].to_i
              break
            end
          end
          @buffer.clear
        end

        # @return [void]
        def parse_message_from_buffer
          begin
            msg = JSON.parse(@buffer)
            @message_handler.call msg unless @message_handler.nil?
          rescue JSON::ParserError => e
            Solargraph::Logging.logger.warn "Failed to parse request: #{e.message}"
            Solargraph::Logging.logger.debug "Buffer: #{@buffer}"
          ensure
            @buffer.clear
            @in_header = true
            @content_length = 0
          end
        end
      end
    end
  end
end
