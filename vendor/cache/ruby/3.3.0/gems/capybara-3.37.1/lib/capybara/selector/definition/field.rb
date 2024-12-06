# frozen_string_literal: true

Capybara.add_selector(:field, locator_type: [String, Symbol]) do
  visible { |options| :hidden if options[:type].to_s == 'hidden' }

  xpath do |locator, **options|
    invalid_types = %w[submit image]
    invalid_types << 'hidden' unless options[:type].to_s == 'hidden'
    xpath = XPath.descendant(:input, :textarea, :select)[!XPath.attr(:type).one_of(*invalid_types)]
    locate_field(xpath, locator, **options)
  end

  expression_filter(:type) do |expr, type|
    type = type.to_s
    if %w[textarea select].include?(type)
      expr.self(type.to_sym)
    else
      expr[XPath.attr(:type) == type]
    end
  end

  filter_set(:_field) # checked/unchecked/disabled/multiple/name/placeholder

  node_filter(:readonly, :boolean) { |node, value| !(value ^ node.readonly?) }

  node_filter(:with) do |node, with|
    val = node.value
    (with.is_a?(Regexp) ? with.match?(val) : val == with.to_s).tap do |res|
      add_error("Expected value to be #{with.inspect} but was #{val.inspect}") unless res
    end
  end

  describe_expression_filters do |type: nil, **|
    " of type #{type.inspect}" if type
  end

  describe_node_filters do |**options|
    " with value #{options[:with].to_s.inspect}" if options.key?(:with)
  end
end
