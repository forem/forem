require 'forwardable'
require 'honeybadger/cli/main'
require 'honeybadger/cli/helpers'
require 'honeybadger/util/http'

module Honeybadger
  module CLI
    class Deploy
      extend Forwardable
      include Helpers::BackendCmd

      def initialize(options, args, config)
        @options = options
        @args = args
        @config = config
        @shell = ::Thor::Base.shell.new
      end

      def run
        payload = {
          environment: config.get(:env),
          revision: options['revision'],
          repository: options['repository'],
          local_username: options['user']
        }

        response = config.backend.notify(:deploys, payload)
        if response.success?
          say("Deploy notification complete.", :green)
        else
          say(error_message(response), :red)
          exit(1)
        end
      end

      private

      attr_reader :options, :args, :config

      def_delegator :@shell, :say
    end
  end
end
