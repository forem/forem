# frozen_string_literal: true

require 'puma/const'

module Puma
  # The implementation of a detailed error logging.
  # @version 5.0.0
  #
  class ErrorLogger
    include Const

    attr_reader :ioerr

    REQUEST_FORMAT = %{"%s %s%s" - (%s)}

    def initialize(ioerr)
      @ioerr = ioerr

      @debug = ENV.key? 'PUMA_DEBUG'
    end

    def self.stdio
      new $stderr
    end

    # Print occurred error details.
    # +options+ hash with additional options:
    # - +error+ is an exception object
    # - +req+ the http request
    # - +text+ (default nil) custom string to print in title
    #   and before all remaining info.
    #
    def info(options={})
      log title(options)
    end

    # Print occurred error details only if
    # environment variable PUMA_DEBUG is defined.
    # +options+ hash with additional options:
    # - +error+ is an exception object
    # - +req+ the http request
    # - +text+ (default nil) custom string to print in title
    #   and before all remaining info.
    #
    def debug(options={})
      return unless @debug

      error = options[:error]
      req = options[:req]

      string_block = []
      string_block << title(options)
      string_block << request_dump(req) if request_parsed?(req)
      string_block << error.backtrace if error

      log string_block.join("\n")
    end

    def title(options={})
      text = options[:text]
      req = options[:req]
      error = options[:error]

      string_block = ["#{Time.now}"]
      string_block << " #{text}" if text
      string_block << " (#{request_title(req)})" if request_parsed?(req)
      string_block << ": #{error.inspect}" if error
      string_block.join('')
    end

    def request_dump(req)
      "Headers: #{request_headers(req)}\n" \
      "Body: #{req.body}"
    end

    def request_title(req)
      env = req.env

      REQUEST_FORMAT % [
        env[REQUEST_METHOD],
        env[REQUEST_PATH] || env[PATH_INFO],
        env[QUERY_STRING] || "",
        env[HTTP_X_FORWARDED_FOR] || env[REMOTE_ADDR] || "-"
      ]
    end

    def request_headers(req)
      headers = req.env.select { |key, _| key.start_with?('HTTP_') }
      headers.map { |key, value| [key[5..-1], value] }.to_h.inspect
    end

    def request_parsed?(req)
      req && req.env[REQUEST_METHOD]
    end

    private

    def log(str)
      ioerr.puts str

      ioerr.flush unless ioerr.sync
    end
  end
end
