# frozen_string_literal: true

Capybara.add_selector(:element, locator_type: [String, Symbol]) do
  xpath do |locator, **|
    XPath.descendant.where(locator ? XPath.local_name == locator.to_s : nil)
  end

  expression_filter(:attributes, matcher: /.+/) do |xpath, name, val|
    builder(xpath).add_attribute_conditions(name => val)
  end

  node_filter(:attributes, matcher: /.+/) do |node, name, val|
    next true unless val.is_a?(Regexp)

    (val.match? node[name]).tap do |res|
      add_error("Expected #{name} to match #{val.inspect} but it was #{node[name]}") unless res
    end
  end

  describe_expression_filters do |**options|
    boolean_values = [true, false]
    booleans, values = options.partition { |_k, v| boolean_values.include? v }.map(&:to_h)
    desc = describe_all_expression_filters(**values)
    desc + booleans.map do |k, v|
      v ? " with #{k} attribute" : "without #{k} attribute"
    end.join
  end
end
