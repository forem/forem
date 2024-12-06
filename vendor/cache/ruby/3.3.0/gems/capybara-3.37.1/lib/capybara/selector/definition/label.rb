# frozen_string_literal: true

Capybara.add_selector(:label, locator_type: [String, Symbol]) do
  label 'label'
  xpath(:for) do |locator, **options|
    xpath = XPath.descendant(:label)
    unless locator.nil?
      locator_matchers = XPath.string.n.is(locator.to_s) | (XPath.attr(:id) == locator.to_s)
      locator_matchers |= XPath.attr(test_id) == locator if test_id
      xpath = xpath[locator_matchers]
    end
    if options.key?(:for)
      for_option = options[:for]
      for_option = for_option[:id] if for_option.is_a?(Capybara::Node::Element)
      if for_option && (for_option != '')
        with_attr = builder(XPath.self).add_attribute_conditions(for: for_option)
        wrapped = !XPath.attr(:for) &
                  builder(XPath.self.descendant(*labelable_elements)).add_attribute_conditions(id: for_option)
        xpath = xpath[with_attr | wrapped]
      end
    end
    xpath
  end

  node_filter(:for) do |node, field_or_value|
    case field_or_value
    when Capybara::Node::Element
      if (for_val = node[:for])
        field_or_value[:id] == for_val
      else
        field_or_value.find_xpath('./ancestor::label[1]').include? node.base
      end
    when Regexp
      if (for_val = node[:for])
        field_or_value.match? for_val
      else
        node.find_xpath(XPath.descendant(*labelable_elements).to_s)
            .any? { |n| field_or_value.match? n[:id] }
      end
    else
      # Non element/regexp values were handled through the expression filter
      true
    end
  end

  describe_expression_filters do |**options|
    next unless options.key?(:for) && !options[:for].is_a?(Capybara::Node::Element)

    if options[:for].is_a? Regexp
      " for element with id matching #{options[:for].inspect}"
    else
      " for element with id of \"#{options[:for]}\""
    end
  end
  describe_node_filters do |**options|
    " for element #{options[:for]}" if options[:for].is_a?(Capybara::Node::Element)
  end

  def labelable_elements
    %i[button input keygen meter output progress select textarea]
  end
end
