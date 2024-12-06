# frozen_string_literal: true

Capybara.add_selector(:fieldset, locator_type: [String, Symbol]) do
  xpath do |locator, legend: nil, **|
    locator_matchers = (XPath.attr(:id) == locator.to_s) | XPath.child(:legend)[XPath.string.n.is(locator.to_s)]
    locator_matchers |= XPath.attr(test_id) == locator.to_s if test_id
    xpath = XPath.descendant(:fieldset)[locator && locator_matchers]
    xpath = xpath[XPath.child(:legend)[XPath.string.n.is(legend)]] if legend
    xpath
  end

  node_filter(:disabled, :boolean) { |node, value| !(value ^ node.disabled?) }
  expression_filter(:disabled) { |xpath, val| val ? xpath : xpath[~XPath.attr(:disabled)] }
end
