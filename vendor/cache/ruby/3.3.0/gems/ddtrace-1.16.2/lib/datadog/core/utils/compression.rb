# frozen_string_literal: true

require 'stringio'
require 'zlib'

module Datadog
  module Core
    module Utils
      # Compression/decompression utility functions.
      #
      # @deprecated This is no longer used by ddtrace and will be removed in 2.0.
      module Compression
        module_function

        # @deprecated This is no longer used by ddtrace and will be removed in 2.0.
        def gzip(string, level: nil, strategy: nil)
          sio = StringIO.new
          sio.binmode
          gz = Zlib::GzipWriter.new(sio, level, strategy)
          gz.write(string)
          gz.close
          sio.string
        end

        # @deprecated This is no longer used by ddtrace and will be removed in 2.0.
        def gunzip(string, encoding = ::Encoding::ASCII_8BIT)
          sio = StringIO.new(string)
          gz = Zlib::GzipReader.new(sio, encoding: encoding)
          gz.read
        ensure
          gz && gz.close
        end
      end
    end
  end
end
