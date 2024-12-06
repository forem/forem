# frozen_string_literal: true

module Ferrum
  class Page
    module Stream
      STREAM_CHUNK = 128 * 1024

      def stream_to(path:, encoding:, handle:)
        if path.nil?
          stream_to_memory(encoding: encoding, handle: handle)
        else
          stream_to_file(path: path, handle: handle)
        end
      end

      def stream_to_file(path:, handle:)
        File.open(path, "wb") { |f| stream(output: f, handle: handle) }
        true
      end

      def stream_to_memory(encoding:, handle:)
        data = String.new # Mutable string has << and compatible to File
        stream(output: data, handle: handle)
        encoding == :base64 ? Base64.encode64(data) : data
      end

      def stream(output:, handle:)
        loop do
          result = command("IO.read", handle: handle, size: STREAM_CHUNK)
          chunk = result.fetch("data")
          chunk = Base64.decode64(chunk) if result["base64Encoded"]
          output << chunk
          break if result["eof"]
        end
      end
    end
  end
end
