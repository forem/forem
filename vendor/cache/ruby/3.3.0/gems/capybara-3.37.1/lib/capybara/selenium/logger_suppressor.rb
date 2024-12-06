# frozen_string_literal: true

module Capybara
  module Selenium
    module DeprecationSuppressor
      def initialize(*)
        @suppress_for_capybara = false
        super
      end

      def deprecate(*args, **opts, &block)
        return if @suppress_for_capybara

        if opts.empty?
          super(*args, &block) # support Selenium 3
        else
          super
        end
      end

      def suppress_deprecations
        prev_suppress_for_capybara, @suppress_for_capybara = @suppress_for_capybara, true
        yield
      ensure
        @suppress_for_capybara = prev_suppress_for_capybara
      end
    end

    module ErrorSuppressor
      def for_code(*)
        ::Selenium::WebDriver.logger.suppress_deprecations do
          super
        end
      end
    end
  end
end

Selenium::WebDriver::Logger.prepend Capybara::Selenium::DeprecationSuppressor
Selenium::WebDriver::Error.singleton_class.prepend Capybara::Selenium::ErrorSuppressor
