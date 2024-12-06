# frozen_string_literal: true

Capybara.add_selector(:option, locator_type: [String, Symbol, Integer]) do
  xpath do |locator|
    xpath = XPath.descendant(:option)
    xpath = xpath[XPath.string.n.is(locator.to_s)] unless locator.nil?
    xpath
  end

  node_filter(:disabled, :boolean) { |node, value| !(value ^ node.disabled?) }
  expression_filter(:disabled) { |xpath, val| val ? xpath : xpath[~XPath.attr(:disabled)] }

  node_filter(:selected, :boolean) { |node, value| !(value ^ node.selected?) }

  describe_expression_filters do |disabled: nil, **options|
    desc = +''
    desc << ' that is not disabled' if disabled == false
    (expression_filters.keys & options.keys).inject(desc) { |memo, ef| memo << " with #{ef} #{options[ef]}" }
  end

  describe_node_filters do |**options|
    desc = +''
    desc << ' that is disabled' if options[:disabled]
    desc << " that is#{' not' unless options[:selected]} selected" if options.key?(:selected)
    desc
  end
end
