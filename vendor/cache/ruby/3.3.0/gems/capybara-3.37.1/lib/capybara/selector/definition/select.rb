# frozen_string_literal: true

Capybara.add_selector(:select, locator_type: [String, Symbol]) do
  label 'select box'

  xpath do |locator, **options|
    xpath = XPath.descendant(:select)
    locate_field(xpath, locator, **options)
  end

  filter_set(:_field, %i[disabled multiple name placeholder])

  node_filter(:options) do |node, options|
    actual = options_text(node)
    (options.sort == actual.sort).tap do |res|
      add_error("Expected options #{options.inspect} found #{actual.inspect}") unless res
    end
  end

  node_filter(:enabled_options) do |node, options|
    actual = options_text(node) { |o| !o.disabled? }
    (options.sort == actual.sort).tap do |res|
      add_error("Expected enabled options #{options.inspect} found #{actual.inspect}") unless res
    end
  end

  node_filter(:disabled_options) do |node, options|
    actual = options_text(node, &:disabled?)
    (options.sort == actual.sort).tap do |res|
      add_error("Expected disabled options #{options.inspect} found #{actual.inspect}") unless res
    end
  end

  expression_filter(:with_options) do |expr, options|
    options.inject(expr) do |xpath, option|
      xpath.where(expression_for(:option, option))
    end
  end

  node_filter(:selected) do |node, selected|
    actual = options_text(node, visible: false, &:selected?)
    (Array(selected).sort == actual.sort).tap do |res|
      add_error("Expected #{selected.inspect} to be selected found #{actual.inspect}") unless res
    end
  end

  node_filter(:with_selected) do |node, selected|
    actual = options_text(node, visible: false, &:selected?)
    (Array(selected) - actual).empty?.tap do |res|
      add_error("Expected at least #{selected.inspect} to be selected found #{actual.inspect}") unless res
    end
  end

  describe_expression_filters do |with_options: nil, **|
    desc = +''
    desc << " with at least options #{with_options.inspect}" if with_options
    desc
  end

  describe_node_filters do |
    options: nil, disabled_options: nil, enabled_options: nil,
    selected: nil, with_selected: nil,
    disabled: nil, **|
    desc = +''
    desc << " with options #{options.inspect}" if options
    desc << " with disabled options #{disabled_options.inspect}}" if disabled_options
    desc << " with enabled options #{enabled_options.inspect}" if enabled_options
    desc << " with #{selected.inspect} selected" if selected
    desc << " with at least #{with_selected.inspect} selected" if with_selected
    desc << ' which is disabled' if disabled
    desc
  end

  def options_text(node, **opts, &filter_block)
    opts[:wait] = false
    opts[:visible] = false unless node.visible?
    node.all(:xpath, './/option', **opts, &filter_block).map do |o|
      o.text((:all if opts[:visible] == false))
    end
  end
end
