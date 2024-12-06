# frozen_string_literal: true

Capybara.add_selector(:frame, locator_type: [String, Symbol]) do
  xpath do |locator, name: nil, **|
    xpath = XPath.descendant(:iframe).union(XPath.descendant(:frame))
    unless locator.nil?
      locator_matchers = (XPath.attr(:id) == locator.to_s) | (XPath.attr(:name) == locator.to_s)
      locator_matchers |= XPath.attr(test_id) == locator if test_id
      xpath = xpath[locator_matchers]
    end
    xpath[find_by_attr(:name, name)]
  end

  describe_expression_filters do |name: nil, **|
    " with name #{name}" if name
  end
end
