# frozen_string_literal: true

require 'capybara/selector/xpath_extensions'
require 'capybara/selector/selector'
require 'capybara/selector/definition'

#
# All Selectors below support the listed selector specific filters in addition to the following system-wide filters
#   * :id (String, Regexp, XPath::Expression) - Matches the id attribute
#   * :class (String, Array<String | Regexp>, Regexp, XPath::Expression) - Matches the class(es) provided
#   * :style (String, Regexp, Hash<String, String>) - Match on elements style
#   * :above (Element) - Match elements above the passed element on the page
#   * :below (Element) - Match elements below the passed element on the page
#   * :left_of (Element) - Match elements left of the passed element on the page
#   * :right_of (Element) - Match elements right of the passed element on the page
#   * :near (Element) - Match elements near (within 50px) the passed element on the page
#   * :focused (Boolean) - Match elements with focus (requires driver support)
#
# ### Built-in Selectors
#
# * **:xpath** - Select elements by XPath expression
#   * Locator: An XPath expression
#
# * **:css** - Select elements by CSS selector
#   * Locator: A CSS selector
#
# * **:id** - Select element by id
#   * Locator: (String, Regexp, XPath::Expression) The id of the element to match
#
# * **:field** - Select field elements (input [not of type submit, image, or hidden], textarea, select)
#   * Locator: Matches against the id, {Capybara.configure test_id} attribute, name, placeholder, or
#     associated label text
#   * Filters:
#       * :name (String, Regexp) - Matches the name attribute
#       * :placeholder (String, Regexp) - Matches the placeholder attribute
#       * :type (String) - Matches the type attribute of the field or element type for 'textarea' and 'select'
#       * :readonly (Boolean) - Match on the element being readonly
#       * :with (String, Regexp) - Matches the current value of the field
#       * :checked (Boolean) - Match checked fields?
#       * :unchecked (Boolean) - Match unchecked fields?
#       * :disabled (Boolean, :all) - Match disabled field? (Default: false)
#       * :multiple (Boolean) - Match fields that accept multiple values
#       * :valid (Boolean) - Match fields that are valid/invalid according to HTML5 form validation
#       * :validation_message (String, Regexp) - Matches the elements current validationMessage
#
# * **:fieldset** - Select fieldset elements
#   * Locator: Matches id, {Capybara.configure test_id}, or contents of wrapped legend
#   * Filters:
#       * :legend (String) - Matches contents of wrapped legend
#       * :disabled (Boolean) - Match disabled fieldset?
#
# * **:link** - Find links (`<a>` elements with an href attribute)
#   * Locator: Matches the id, {Capybara.configure test_id}, or title attributes, or the string content of the link,
#     or the alt attribute of a contained img element. By default this selector requires a link to have an href attribute.
#   * Filters:
#       * :title (String) - Matches the title attribute
#       * :alt (String) - Matches the alt attribute of a contained img element
#       * :href (String, Regexp, nil, false) - Matches the normalized href of the link, if nil will find `<a>` elements with no href attribute, if false ignores href presence
#
# * **:button** - Find buttons ( input [of type submit, reset, image, button] or button elements )
#   * Locator: Matches the id, {Capybara.configure test_id} attribute, name, value, or title attributes, string content of a button, or the alt attribute of an image type button or of a descendant image of a button
#   * Filters:
#       * :name (String, Regexp) - Matches the name attribute
#       * :title (String) - Matches the title attribute
#       * :value (String) - Matches the value of an input button
#       * :type (String) - Matches the type attribute
#       * :disabled (Boolean, :all) - Match disabled buttons (Default: false)
#
# * **:link_or_button** - Find links or buttons
#   * Locator: See :link and :button selectors
#   * Filters:
#       * :disabled (Boolean, :all) - Match disabled buttons? (Default: false)
#
# * **:fillable_field** - Find text fillable fields ( textarea, input [not of type submit, image, radio, checkbox, hidden, file] )
#   * Locator: Matches against the id, {Capybara.configure test_id} attribute, name, placeholder, or associated label text
#   * Filters:
#       * :name (String, Regexp) - Matches the name attribute
#       * :placeholder (String, Regexp) - Matches the placeholder attribute
#       * :with (String, Regexp) - Matches the current value of the field
#       * :type (String) - Matches the type attribute of the field or element type for 'textarea'
#       * :disabled (Boolean, :all) - Match disabled field? (Default: false)
#       * :multiple (Boolean) - Match fields that accept multiple values
#       * :valid (Boolean) - Match fields that are valid/invalid according to HTML5 form validation
#       * :validation_message (String, Regexp) - Matches the elements current validationMessage
#
# * **:radio_button** - Find radio buttons
#   * Locator: Match id, {Capybara.configure test_id} attribute, name, or associated label text
#   * Filters:
#       * :name (String, Regexp) - Matches the name attribute
#       * :checked (Boolean) - Match checked fields?
#       * :unchecked (Boolean) - Match unchecked fields?
#       * :disabled (Boolean, :all) - Match disabled field? (Default: false)
#       * :option (String, Regexp) - Match the current value
#       * :with - Alias of :option
#
# * **:checkbox** - Find checkboxes
#   * Locator: Match id, {Capybara.configure test_id} attribute, name, or associated label text
#   * Filters:
#       * :name (String, Regexp) - Matches the name attribute
#       * :checked (Boolean) - Match checked fields?
#       * :unchecked (Boolean) - Match unchecked fields?
#       * :disabled (Boolean, :all) - Match disabled field? (Default: false)
#       * :with (String, Regexp) - Match the current value
#       * :option - Alias of :with
#
# * **:select** - Find select elements
#   * Locator: Match id, {Capybara.configure test_id} attribute, name, placeholder, or associated label text
#   * Filters:
#       * :name (String, Regexp) - Matches the name attribute
#       * :placeholder (String, Placeholder) - Matches the placeholder attribute
#       * :disabled (Boolean, :all) - Match disabled field? (Default: false)
#       * :multiple (Boolean) - Match fields that accept multiple values
#       * :options (Array<String>) - Exact match options
#       * :enabled_options (Array<String>) - Exact match enabled options
#       * :disabled_options (Array<String>) - Exact match disabled options
#       * :with_options (Array<String>) - Partial match options
#       * :selected (String, Array<String>) - Match the selection(s)
#       * :with_selected (String, Array<String>) - Partial match the selection(s)
#
# * **:option** - Find option elements
#   * Locator: Match text of option
#   * Filters:
#       * :disabled (Boolean) - Match disabled option
#       * :selected (Boolean) - Match selected option
#
# * **:datalist_input** - Find input field with datalist completion
#   * Locator: Matches against the id, {Capybara.configure test_id} attribute, name,
#     placeholder, or associated label text
#   * Filters:
#       * :name (String, Regexp) - Matches the name attribute
#       * :placeholder (String, Regexp) - Matches the placeholder attribute
#       * :disabled (Boolean, :all) - Match disabled field? (Default: false)
#       * :options (Array<String>) - Exact match options
#       * :with_options (Array<String>) - Partial match options
#
# * **:datalist_option** - Find datalist option
#   * Locator: Match text or value of option
#   * Filters:
#       * :disabled (Boolean) - Match disabled option
#
# * **:file_field** - Find file input elements
#   * Locator: Match id, {Capybara.configure test_id} attribute, name, or associated label text
#   * Filters:
#       * :name (String, Regexp) - Matches the name attribute
#       * :disabled (Boolean, :all) - Match disabled field? (Default: false)
#       * :multiple (Boolean) - Match field that accepts multiple values
#
# * **:label** - Find label elements
#   * Locator: Match id, {Capybara.configure test_id}, or text contents
#   * Filters:
#       * :for (Element, String, Regexp) - The element or id of the element associated with the label
#
# * **:table** - Find table elements
#   * Locator: id, {Capybara.configure test_id}, or caption text of table
#   * Filters:
#       * :caption (String) - Match text of associated caption
#       * :with_rows (Array<Array<String>>, Array<Hash<String, String>>) - Partial match `<td>` data - visibility of `<td>` elements is not considered
#       * :rows (Array<Array<String>>) - Match all `<td>`s - visibility of `<td>` elements is not considered
#       * :with_cols (Array<Array<String>>, Array<Hash<String, String>>) - Partial match `<td>` data - visibility of `<td>` elements is not considered
#       * :cols (Array<Array<String>>) - Match all `<td>`s - visibility of `<td>` elements is not considered
#
# * **:table_row** - Find table row
#   * Locator: Array<String>, Hash<String, String> table row `<td>` contents - visibility of `<td>` elements is not considered
#
# * **:frame** - Find frame/iframe elements
#   * Locator: Match id, {Capybara.configure test_id} attribute, or name
#   * Filters:
#       * :name (String) - Match name attribute
#
# * **:element**
#   * Locator: Type of element ('div', 'a', etc) - if not specified defaults to '*'
#   * Filters:
#       * :\<any> (String, Regexp) - Match on any specified element attribute
#
class Capybara::Selector; end # rubocop:disable Lint/EmptyClass

Capybara::Selector::FilterSet.add(:_field) do
  node_filter(:checked, :boolean) { |node, value| !(value ^ node.checked?) }
  node_filter(:unchecked, :boolean) { |node, value| (value ^ node.checked?) }
  node_filter(:disabled, :boolean, default: false, skip_if: :all) { |node, value| !(value ^ node.disabled?) }
  node_filter(:valid, :boolean) { |node, value| node.evaluate_script('this.validity.valid') == value }
  node_filter(:name) { |node, value| !value.is_a?(Regexp) || value.match?(node[:name]) }
  node_filter(:placeholder) { |node, value| !value.is_a?(Regexp) || value.match?(node[:placeholder]) }
  node_filter(:validation_message) do |node, msg|
    vm = node[:validationMessage]
    (msg.is_a?(Regexp) ? msg.match?(vm) : vm == msg.to_s).tap do |res|
      add_error("Expected validation message to be #{msg.inspect} but was #{vm}") unless res
    end
  end

  expression_filter(:name) do |xpath, val|
    builder(xpath).add_attribute_conditions(name: val)
  end
  expression_filter(:placeholder) do |xpath, val|
    builder(xpath).add_attribute_conditions(placeholder: val)
  end
  expression_filter(:disabled) { |xpath, val| val ? xpath : xpath[~XPath.attr(:disabled)] }
  expression_filter(:multiple) { |xpath, val| xpath[val ? XPath.attr(:multiple) : ~XPath.attr(:multiple)] }

  describe(:expression_filters) do |name: nil, placeholder: nil, disabled: nil, multiple: nil, **|
    desc = +''
    desc << ' that is not disabled' if disabled == false
    desc << " with name #{name}" if name
    desc << " with placeholder #{placeholder}" if placeholder
    desc << ' with the multiple attribute' if multiple == true
    desc << ' without the multiple attribute' if multiple == false
    desc
  end

  describe(:node_filters) do |checked: nil, unchecked: nil, disabled: nil, valid: nil, validation_message: nil, **|
    desc, states = +'', []
    states << 'checked' if checked || (unchecked == false)
    states << 'not checked' if unchecked || (checked == false)
    states << 'disabled' if disabled == true
    desc << " that is #{states.join(' and ')}" unless states.empty?
    desc << ' that is valid' if valid == true
    desc << ' that is invalid' if valid == false
    desc << " with validation message #{validation_message.to_s.inspect}" if validation_message
    desc
  end
end

require 'capybara/selector/definition/xpath'
require 'capybara/selector/definition/css'
require 'capybara/selector/definition/id'
require 'capybara/selector/definition/field'
require 'capybara/selector/definition/fieldset'
require 'capybara/selector/definition/link'
require 'capybara/selector/definition/button'
require 'capybara/selector/definition/link_or_button'
require 'capybara/selector/definition/fillable_field'
require 'capybara/selector/definition/radio_button'
require 'capybara/selector/definition/checkbox'
require 'capybara/selector/definition/select'
require 'capybara/selector/definition/datalist_input'
require 'capybara/selector/definition/option'
require 'capybara/selector/definition/datalist_option'
require 'capybara/selector/definition/file_field'
require 'capybara/selector/definition/label'
require 'capybara/selector/definition/table'
require 'capybara/selector/definition/table_row'
require 'capybara/selector/definition/frame'
require 'capybara/selector/definition/element'
