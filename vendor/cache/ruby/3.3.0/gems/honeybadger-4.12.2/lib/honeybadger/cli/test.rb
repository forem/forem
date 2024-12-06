require 'erb'
require 'forwardable'
require 'honeybadger/cli/main'
require 'pathname'

module Honeybadger
  module CLI
    class Test
      extend Forwardable

      TEST_EXCEPTION = begin
                         exception_name = ENV['EXCEPTION'] || 'HoneybadgerTestingException'
                         Object.const_get(exception_name)
                       rescue
                         Object.const_set(exception_name, Class.new(Exception))
                       end.new('Testing honeybadger via "honeybadger test". If you can see this, it works.')

      class TestBackend
        def initialize(backend)
          @backend = backend
        end

        def self.callings
          @callings ||= Hash.new {|h,k| h[k] = [] }
        end

        def notify(feature, payload)
          response = @backend.notify(feature, payload)
          self.class.callings[feature] << [payload, response]
          response
        end
      end

      def initialize(options)
        @options = options
        @shell = ::Thor::Base.shell.new
      end

      def run
        begin
          require File.join(Dir.pwd, 'config', 'environment.rb')
          raise LoadError unless defined?(::Rails.application)
          say("Detected Rails #{Rails::VERSION::STRING}")
        rescue LoadError
          require 'honeybadger/init/ruby'
        end

        if Honeybadger.config.get(:api_key).to_s =~ BLANK
          say("Unable to send test: Honeybadger API key is missing.", :red)
          exit(1)
        end

        Honeybadger.config.set(:report_data, !options[:dry_run])
        test_backend = TestBackend.new(Honeybadger.config.backend)
        Honeybadger.config.backend = test_backend

        at_exit do
          # Exceptions will already be reported when exiting.
          verify_test unless $!
        end

        run_test
      end

      private

      attr_reader :options

      def_delegator :@shell, :say

      def run_test
        if defined?(::Rails.application) && ::Rails.application
          run_rails_test
        else
          run_standalone_test
        end
      end

      def test_exception_class
        exception_name = ENV['EXCEPTION'] || 'HoneybadgerTestingException'
        Object.const_get(exception_name)
      rescue
        Object.const_set(exception_name, Class.new(Exception))
      end

      def run_standalone_test
        Honeybadger.notify(TEST_EXCEPTION)
      end

      def run_rails_test
        # Suppress error logging in Rails' exception handling middleware. Rails 3.0
        # uses ActionDispatch::ShowExceptions to rescue/show exceptions, but does
        # not log anything but application trace. Rails 3.2 now falls back to
        # logging the framework trace (moved to ActionDispatch::DebugExceptions),
        # which caused cluttered output while running the test task.
        defined?(::ActionDispatch::DebugExceptions) and
          ::ActionDispatch::DebugExceptions.class_eval { def logger(*args) ; @logger ||= Logger.new(nil) ; end }
        defined?(::ActionDispatch::ShowExceptions) and
          ::ActionDispatch::ShowExceptions.class_eval { def logger(*args) ; @logger ||= Logger.new(nil) ; end }

        # Detect and disable the better_errors gem
        if defined?(::BetterErrors::Middleware)
          say('Better Errors detected: temporarily disabling middleware.', :yellow)
          ::BetterErrors::Middleware.class_eval { def call(env) @app.call(env); end }
        end

        begin
          require './app/controllers/application_controller'
        rescue LoadError
          nil
        end

        unless defined?(::ApplicationController)
          say('Error: No ApplicationController found.', :red)
          return false
        end

        eval(<<-CONTROLLER)
        class Honeybadger::TestController < ApplicationController
          # This is to bypass any filters that may prevent access to the action.
          if respond_to?(:prepend_before_action)
            prepend_before_action :test_honeybadger
          else
            prepend_before_filter :test_honeybadger
          end
          def test_honeybadger
            puts "Raising '#{Honeybadger::CLI::Test::TEST_EXCEPTION.class.name}' to simulate application failure."
            raise Honeybadger::CLI::Test::TEST_EXCEPTION
          end
          # Ensure we actually have an action to go to.
          def verify; end
        end
        CONTROLLER

        ::Rails.application.routes.tap do |r|
          # RouteSet#disable_clear_and_finalize prevents existing routes from
          # being cleared. We'll set it back to the original value when we're
          # done so not to mess with Rails state.
          d = r.disable_clear_and_finalize
          begin
            r.disable_clear_and_finalize = true
            r.clear!
            r.draw do
              match 'verify' => 'honeybadger/test#verify', :as => "verify_#{SecureRandom.hex}", :via => :get
            end
            ::Rails.application.routes_reloader.paths.each{ |path| load(path) }
            ::ActiveSupport.on_load(:action_controller) { r.finalize! }
          ensure
            r.disable_clear_and_finalize = d
          end
        end

        ssl = defined?(::Rails.configuration.force_ssl) && ::Rails.configuration.force_ssl
        env = ::Rack::MockRequest.env_for("http#{ ssl ? 's' : nil }://www.example.com/verify", 'REMOTE_ADDR' => '127.0.0.1', 'HTTP_HOST' => 'localhost')

        ::Rails.application.call(env)
      end

      def verify_test
        Honeybadger.flush

        if calling = TestBackend.callings[:notices].find {|c| c[0].exception.eql?(TEST_EXCEPTION) }
          notice, response = *calling

          if !response.success?
            host = Honeybadger.config.get(:'connection.host')
            say(<<-MSG, :red)
!! --- Honeybadger test failed ------------------------------------------------ !!

The error notifier is installed, but we encountered an error:

  #{response.error_message}

To fix this issue, please try the following:

  - Make sure the gem is configured properly.
  - Retry executing this command a few times.
  - Make sure you can connect to #{host} (`curl https://#{host}/v1/notices`).
  - Email support@honeybadger.io for help. Include as much debug info as you
    can for a faster resolution!

!! --- End -------------------------------------------------------------------- !!
MSG
            exit(1)
          end

          say(generate_success_message(response), :green)

          exit(0)
        end

        say(<<-MSG, :red)
!! --- Honeybadger test failed ------------------------------------------------ !!

Error: The test exception was not reported; the application may not be
configured properly.

This is usually caused by one of the following issues:

  - There was a problem loading your application. Check your logs to see if a
    different exception is being raised.
  - The exception is being rescued before it reaches our Rack middleware. If
    you're using `rescue` or `rescue_from` you may need to notify Honeybadger
    manually: `Honeybadger.notify(exception)`.
  - The honeybadger gem is misconfigured. Check the settings in your
    honeybadger.yml file.
MSG

        notices = TestBackend.callings[:notices].map(&:first)
        unless notices.empty?
          say("\nThe following errors were reported:", :red)
          notices.each {|n| say("\n  - #{n.error_class}: #{n.error_message}", :red) }
        end

        say("\nSee https://docs.honeybadger.io/gem-troubleshooting for more troubleshooting help.\n\n", :red)
        say("!! --- End -------------------------------------------------------------------- !!", :red)

        exit(1)
      end

      def generate_success_message(response)
        notice_id = JSON.parse(response.body)['id']
        notice_url = "https://app.honeybadger.io/notice/#{notice_id}"

        unless options[:install]
          return "⚡ Success: #{notice_url}"
        end

        <<-MSG
⚡ --- Honeybadger is installed! -----------------------------------------------

Good news: You're one deploy away from seeing all of your exceptions in
Honeybadger. For now, we've generated a test exception for you:

  #{notice_url}

Optional steps:

  - Show a feedback form on your error page:
    https://docs.honeybadger.io/gem-feedback
  - Show a UUID or link to Honeybadger on your error page:
    https://docs.honeybadger.io/gem-informer
  - Track deployments (if you're using Capistrano, we already did this):
    https://docs.honeybadger.io/gem-deploys

If you ever need help:

  - Read the gem troubleshooting guide: https://docs.honeybadger.io/gem-troubleshooting
  - Check out our documentation: https://docs.honeybadger.io/
  - Email the founders: support@honeybadger.io

Most people don't realize that Honeybadger is a small, bootstrapped company. We
really couldn't do this without you. Thank you for allowing us to do what we
love: making developers awesome.

Happy 'badgering!

Sincerely,
The Honeybadger Crew
https://www.honeybadger.io/about/

⚡ --- End --------------------------------------------------------------------
MSG
      end
    end
  end
end
