# frozen_string_literal: true

Capybara.add_selector(:xpath, locator_type: [:to_xpath, String], raw_locator: true) do
  xpath { |xpath| xpath }
end
