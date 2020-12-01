module RSpec
  module Rails
    # @api public
    # Container class for system tests
    module SystemExampleGroup
      extend ActiveSupport::Concern
      include RSpec::Rails::RailsExampleGroup
      include RSpec::Rails::Matchers::RedirectTo
      include RSpec::Rails::Matchers::RenderTemplate
      include ActionDispatch::Integration::Runner
      include ActionDispatch::Assertions
      include ActionController::TemplateAssertions

      # Special characters to translate into underscores for #method_name
      CHARS_TO_TRANSLATE = ['/', '.', ':', ',', "'", '"', " "].freeze

      # @private
      module BlowAwayTeardownHooks
        # @private
        def before_teardown
        end

        # @private
        def after_teardown
        end
      end

      # for the SystemTesting Screenshot situation
      def passed?
        return false if RSpec.current_example.exception
        return true unless defined?(::RSpec::Expectations::FailureAggregator)

        failure_notifier = ::RSpec::Support.failure_notifier
        return true unless failure_notifier.is_a?(::RSpec::Expectations::FailureAggregator)

        failure_notifier.failures.empty? && failure_notifier.other_errors.empty?
      end

      # @private
      def method_name
        @method_name ||= [
          self.class.name.underscore,
          RSpec.current_example.description.underscore
        ].join("_").tr(CHARS_TO_TRANSLATE.join, "_")[0...200] + "_#{rand(1000)}"
      end

      # Delegates to `Rails.application`.
      def app
        ::Rails.application
      end

      included do |other|
        ActiveSupport.on_load(:action_dispatch_system_test_case) do
          ActionDispatch::SystemTesting::Server.silence_puma = true
        end

        begin
          require 'capybara'
          require 'action_dispatch/system_test_case'
        rescue LoadError => e
          abort """
            LoadError: #{e.message}
            System test integration requires Rails >= 5.1 and has a hard
            dependency on a webserver and `capybara`, please add capybara to
            your Gemfile and configure a webserver (e.g. `Capybara.server =
            :webrick`) before attempting to use system specs.
          """.gsub(/\s+/, ' ').strip
        end

        if ::Rails::VERSION::STRING >= '6.0'
          original_before_teardown =
            ::ActionDispatch::SystemTesting::TestHelpers::SetupAndTeardown.instance_method(:before_teardown)
        end

        original_after_teardown =
          ::ActionDispatch::SystemTesting::TestHelpers::SetupAndTeardown.instance_method(:after_teardown)

        other.include ::ActionDispatch::SystemTesting::TestHelpers::SetupAndTeardown
        other.include ::ActionDispatch::SystemTesting::TestHelpers::ScreenshotHelper
        other.include BlowAwayTeardownHooks

        attr_reader :driver

        if ActionDispatch::SystemTesting::Server.respond_to?(:silence_puma=)
          ActionDispatch::SystemTesting::Server.silence_puma = true
        end

        def initialize(*args, &blk)
          super(*args, &blk)
          @driver = nil

          self.class.before do
            # A user may have already set the driver, so only default if driver
            # is not set
            driven_by(:selenium) unless @driver
          end
        end

        def driven_by(driver, **driver_options, &blk)
          @driver = ::ActionDispatch::SystemTestCase.driven_by(driver, **driver_options, &blk).tap(&:use)
        end

        before do
          @routes = ::Rails.application.routes
        end

        after do
          orig_stdout = $stdout
          $stdout = StringIO.new
          begin
            if ::Rails::VERSION::STRING >= '6.0'
              original_before_teardown.bind(self).call
            end
            original_after_teardown.bind(self).call
          ensure
            myio = $stdout
            myio.rewind
            RSpec.current_example.metadata[:extra_failure_lines] = myio.readlines
            $stdout = orig_stdout
          end
        end
      end
    end
  end
end
