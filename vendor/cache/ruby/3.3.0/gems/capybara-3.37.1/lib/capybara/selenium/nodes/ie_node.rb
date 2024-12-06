# frozen_string_literal: true

require 'capybara/selenium/extensions/html5_drag'

class Capybara::Selenium::IENode < Capybara::Selenium::Node
  def disabled?
    # super
    # optimize to one script call
    driver.evaluate_script <<~JS.delete("\n"), self
      arguments[0].msMatchesSelector('
        :disabled,
        select:disabled *,
        optgroup:disabled *,
        fieldset[disabled],
        fieldset[disabled] > *:not(legend),
        fieldset[disabled] > *:not(legend) *,
        fieldset[disabled] > legend:nth-of-type(n+2),
        fieldset[disabled] > legend:nth-of-type(n+2) *
      ')
    JS
  end
end
