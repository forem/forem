# frozen_string_literal: true

Capybara.add_selector(:datalist_option, locator_type: [String, Symbol]) do
  label 'datalist option'
  visible(:all)

  xpath do |locator|
    xpath = XPath.descendant(:option)
    xpath = xpath[XPath.string.n.is(locator.to_s) | (XPath.attr(:value) == locator.to_s)] unless locator.nil?
    xpath
  end

  node_filter(:disabled, :boolean) { |node, value| !(value ^ node.disabled?) }
  expression_filter(:disabled) { |xpath, val| val ? xpath : xpath[~XPath.attr(:disabled)] }

  describe_expression_filters do |disabled: nil, **options|
    desc = +''
    desc << ' that is not disabled' if disabled == false
    desc << describe_all_expression_filters(**options)
  end

  describe_node_filters do |**options|
    ' that is disabled' if options[:disabled]
  end
end
