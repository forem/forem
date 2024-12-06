# frozen_string_literal: true

module PauseDurationFix
  def encode
    super.tap { |output| output[:duration] ||= 0 }
  end
end

::Selenium::WebDriver::Interactions::Pause.prepend PauseDurationFix
