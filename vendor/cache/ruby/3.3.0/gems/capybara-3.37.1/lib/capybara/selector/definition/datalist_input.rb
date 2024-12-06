# frozen_string_literal: true

Capybara.add_selector(:datalist_input, locator_type: [String, Symbol]) do
  label 'input box with datalist completion'

  xpath do |locator, **options|
    xpath = XPath.descendant(:input)[XPath.attr(:list)]
    locate_field(xpath, locator, **options)
  end

  filter_set(:_field, %i[disabled name placeholder])

  node_filter(:options) do |node, options|
    actual = node.find("//datalist[@id=#{node[:list]}]", visible: :all).all(:datalist_option, wait: false).map(&:value)
    (options.sort == actual.sort).tap do |res|
      add_error("Expected #{options.inspect} options found #{actual.inspect}") unless res
    end
  end

  expression_filter(:with_options) do |expr, options|
    options.inject(expr) do |xpath, option|
      xpath.where(XPath.attr(:list) == XPath.anywhere(:datalist)[expression_for(:datalist_option, option)].attr(:id))
    end
  end

  describe_expression_filters do |with_options: nil, **|
    desc = +''
    desc << " with at least options #{with_options.inspect}" if with_options
    desc
  end

  describe_node_filters do |options: nil, **|
    " with options #{options.inspect}" if options
  end
end
