# frozen_string_literal: true

module Capybara
  module Selenium
    class PersistentClient < ::Selenium::WebDriver::Remote::Http::Default
      def close
        super
        @http.finish if @http&.started?
      end

    private

      def http
        super.tap do |http|
          http.start unless http.started?
        end
      end
    end
  end
end
