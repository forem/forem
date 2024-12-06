require 'vcr/middleware/excon'

module VCR
  class LibraryHooks
    module Excon
      # @private
      def self.configure_middleware
        middlewares = ::Excon.defaults[:middlewares]

        middlewares << VCR::Middleware::Excon::Request
        response_parser_index = middlewares.index(::Excon::Middleware::ResponseParser)
        middlewares.insert(response_parser_index + 1, VCR::Middleware::Excon::Response)
      end

      configure_middleware
    end
  end
end

VCR.configuration.after_library_hooks_loaded do
  # ensure WebMock's Excon adapter does not conflict with us here
  # (i.e. to double record requests or whatever).
  if defined?(WebMock::HttpLibAdapters::ExconAdapter)
    WebMock::HttpLibAdapters::ExconAdapter.disable!

    if defined?(::RSpec)
      ::RSpec.configure do |config|
        config.before(:suite) do
          WebMock::HttpLibAdapters::ExconAdapter.disable!
        end
      end
    end
  end
end

