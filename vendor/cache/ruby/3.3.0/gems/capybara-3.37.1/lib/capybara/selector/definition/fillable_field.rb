# frozen_string_literal: true

Capybara.add_selector(:fillable_field, locator_type: [String, Symbol]) do
  label 'field'
  xpath do |locator, allow_self: nil, **options|
    xpath = XPath.axis(allow_self ? :'descendant-or-self' : :descendant, :input, :textarea)[
      !XPath.attr(:type).one_of('submit', 'image', 'radio', 'checkbox', 'hidden', 'file')
    ]
    locate_field(xpath, locator, **options)
  end

  expression_filter(:type) do |expr, type|
    type = type.to_s
    if type == 'textarea'
      expr.self(type.to_sym)
    else
      expr[XPath.attr(:type) == type]
    end
  end

  filter_set(:_field, %i[disabled multiple name placeholder valid validation_message])

  node_filter(:with) do |node, with|
    val = node.value
    (with.is_a?(Regexp) ? with.match?(val) : val == with.to_s).tap do |res|
      add_error("Expected value to be #{with.inspect} but was #{val.inspect}") unless res
    end
  end

  describe_node_filters do |**options|
    " with value #{options[:with].to_s.inspect}" if options.key?(:with)
  end
end
