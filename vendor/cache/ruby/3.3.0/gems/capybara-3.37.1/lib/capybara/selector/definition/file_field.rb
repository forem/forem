# frozen_string_literal: true

Capybara.add_selector(:file_field, locator_type: [String, Symbol]) do
  label 'file field'
  xpath do |locator, allow_self: nil, **options|
    xpath = XPath.axis(allow_self ? :'descendant-or-self' : :descendant, :input)[
      XPath.attr(:type) == 'file'
    ]
    locate_field(xpath, locator, **options)
  end

  filter_set(:_field, %i[disabled multiple name])
end
