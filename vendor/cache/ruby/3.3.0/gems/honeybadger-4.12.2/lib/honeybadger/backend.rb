require 'forwardable'

require 'honeybadger/backend/base'
require 'honeybadger/backend/server'
require 'honeybadger/backend/test'
require 'honeybadger/backend/null'
require 'honeybadger/backend/debug'

module Honeybadger
  # @api private
  module Backend
    class BackendError < StandardError; end

    def self.mapping
      @@mapping ||= {
        server: Server,
        test: Test,
        null: Null,
        debug: Debug
      }.freeze
    end

    def self.for(backend)
      mapping[backend] or raise(BackendError, "Unable to locate backend: #{backend}")
    end
  end
end
