# frozen_string_literal: true

Capybara.add_selector(:id, locator_type: [String, Symbol, Regexp]) do
  xpath { |id| builder(XPath.descendant).add_attribute_conditions(id: id) }
  locator_filter { |node, id| id.is_a?(Regexp) ? id.match?(node[:id]) : true }
end
