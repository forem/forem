# frozen_string_literal: true

Capybara.add_selector(:link, locator_type: [String, Symbol]) do
  xpath do |locator, href: true, alt: nil, title: nil, **|
    xpath = XPath.descendant(:a)
    xpath = builder(xpath).add_attribute_conditions(href: href) unless href == false

    if enable_aria_role
      role_path = XPath.descendant[XPath.attr(:role).equals('link')]
      role_path = builder(role_path).add_attribute_conditions(href: href) unless [true, false].include? href

      xpath += role_path
    end

    unless locator.nil?
      locator = locator.to_s
      matchers = [XPath.attr(:id) == locator,
                  XPath.string.n.is(locator),
                  XPath.attr(:title).is(locator),
                  XPath.descendant(:img)[XPath.attr(:alt).is(locator)]]
      matchers << XPath.attr(:'aria-label').is(locator) if enable_aria_label
      matchers << XPath.attr(test_id).equals(locator) if test_id
      xpath = xpath[matchers.reduce(:|)]
    end

    xpath = xpath[find_by_attr(:title, title)]
    xpath = xpath[XPath.descendant(:img)[XPath.attr(:alt) == alt]] if alt

    xpath
  end

  node_filter(:href) do |node, href|
    # If not a Regexp it's been handled in the main XPath
    (href.is_a?(Regexp) ? node[:href].match?(href) : true).tap do |res|
      add_error "Expected href to match #{href.inspect} but it was #{node[:href].inspect}" unless res
    end
  end

  expression_filter(:download, valid_values: [true, false, String]) do |expr, download|
    builder(expr).add_attribute_conditions(download: download)
  end

  describe_expression_filters do |download: nil, **options|
    desc = +''
    if (href = options[:href])
      desc << " with href #{'matching ' if href.is_a? Regexp}#{href.inspect}"
    elsif options.key?(:href) && href != false # is nil specified?
      desc << ' with no href attribute'
    end
    desc << " with download attribute#{" #{download}" if download.is_a? String}" if download
    desc << ' without download attribute' if download == false
    desc
  end
end
