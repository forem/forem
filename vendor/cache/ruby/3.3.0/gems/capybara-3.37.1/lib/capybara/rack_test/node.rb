# frozen_string_literal: true

require 'capybara/rack_test/errors'

class Capybara::RackTest::Node < Capybara::Driver::Node
  BLOCK_ELEMENTS = %w[p h1 h2 h3 h4 h5 h6 ol ul pre address blockquote dl div fieldset form hr noscript table].freeze

  def all_text
    native.text
          .gsub(/[\u200b\u200e\u200f]/, '')
          .gsub(/[\ \n\f\t\v\u2028\u2029]+/, ' ')
          .gsub(/\A[[:space:]&&[^\u00a0]]+/, '')
          .gsub(/[[:space:]&&[^\u00a0]]+\z/, '')
          .tr("\u00a0", ' ')
  end

  def visible_text
    displayed_text.squeeze(' ')
                  .gsub(/[\ \n]*\n[\ \n]*/, "\n")
                  .gsub(/\A[[:space:]&&[^\u00a0]]+/, '')
                  .gsub(/[[:space:]&&[^\u00a0]]+\z/, '')
                  .tr("\u00a0", ' ')
  end

  def [](name)
    string_node[name]
  end

  def style(_styles)
    raise NotImplementedError, 'The rack_test driver does not process CSS'
  end

  def value
    string_node.value
  end

  def set(value, **options)
    return if disabled? || readonly?

    warn "Options passed to Node#set but the RackTest driver doesn't support any - ignoring" unless options.empty?

    if value.is_a?(Array) && !multiple?
      raise TypeError, "Value cannot be an Array when 'multiple' attribute is not present. Not a #{value.class}"
    end

    if radio? then set_radio(value)
    elsif checkbox? then set_checkbox(value)
    elsif range? then set_range(value)
    elsif input_field? then set_input(value)
    elsif textarea? then native['_capybara_raw_value'] = value.to_s
    end
  end

  def select_option
    return if disabled?

    deselect_options unless select_node.multiple?
    native['selected'] = 'selected'
  end

  def unselect_option
    raise Capybara::UnselectNotAllowed, 'Cannot unselect option from single select box.' unless select_node.multiple?

    native.remove_attribute('selected')
  end

  def click(keys = [], **options)
    options.delete(:offset)
    raise ArgumentError, 'The RackTest driver does not support click options' unless keys.empty? && options.empty?

    if link?
      follow_link
    elsif submits?
      associated_form = form
      Capybara::RackTest::Form.new(driver, associated_form).submit(self) if associated_form
    elsif checkable?
      set(!checked?)
    elsif tag_name == 'label'
      click_label
    elsif (details = native.xpath('.//ancestor-or-self::details').last)
      toggle_details(details)
    end
  end

  def tag_name
    native.node_name
  end

  def visible?
    string_node.visible?
  end

  def checked?
    string_node.checked?
  end

  def selected?
    string_node.selected?
  end

  def disabled?
    return true if string_node.disabled?

    if %w[option optgroup].include? tag_name
      find_xpath(OPTION_OWNER_XPATH)[0].disabled?
    else
      !find_xpath(DISABLED_BY_FIELDSET_XPATH).empty?
    end
  end

  def readonly?
    # readonly attribute not valid on these input types
    return false if input_field? && %w[hidden range color checkbox radio file submit image reset button].include?(type)

    super
  end

  def path
    native.path
  end

  def find_xpath(locator, **_hints)
    native.xpath(locator).map { |el| self.class.new(driver, el) }
  end

  def find_css(locator, **_hints)
    native.css(locator, Capybara::RackTest::CSSHandlers.new).map { |el| self.class.new(driver, el) }
  end

  public_instance_methods(false).each do |meth_name|
    alias_method "unchecked_#{meth_name}", meth_name
    private "unchecked_#{meth_name}" # rubocop:disable Style/AccessModifierDeclarations

    if RUBY_VERSION >= '2.7'
      class_eval <<~METHOD, __FILE__, __LINE__ + 1
        def #{meth_name}(...)
          stale_check
          method(:"unchecked_#{meth_name}").call(...)
        end
      METHOD
    else
      define_method meth_name do |*args|
        stale_check
        send("unchecked_#{meth_name}", *args)
      end
    end
  end

protected

  # @api private
  def displayed_text(check_ancestor: true)
    if !string_node.visible?(check_ancestor)
      ''
    elsif native.text?
      native.text
            .gsub(/[\u200b\u200e\u200f]/, '')
            .gsub(/[\ \n\f\t\v\u2028\u2029]+/, ' ')
    elsif native.element?
      text = native.children.map do |child|
        Capybara::RackTest::Node.new(driver, child).displayed_text(check_ancestor: false)
      end.join || ''
      text = "\n#{text}\n" if BLOCK_ELEMENTS.include?(tag_name)
      text
    else # rubocop:disable Lint/DuplicateBranch
      ''
    end
  end

private

  def stale_check
    raise Capybara::RackTest::Errors::StaleElementReferenceError unless native.document == driver.dom
  end

  def deselect_options
    select_node.find_xpath('.//option[@selected]').each { |node| node.native.remove_attribute('selected') }
  end

  def string_node
    @string_node ||= Capybara::Node::Simple.new(native)
  end

  # a reference to the select node if this is an option node
  def select_node
    find_xpath('./ancestor::select[1]').first
  end

  def type
    native[:type]
  end

  def form
    if native[:form]
      native.xpath("//form[@id='#{native[:form]}']")
    else
      native.ancestors('form')
    end.first
  end

  def set_radio(_value) # rubocop:disable Naming/AccessorMethodName
    other_radios_xpath = XPath.generate { |xp| xp.anywhere(:input)[xp.attr(:name) == self[:name]] }.to_s
    driver.dom.xpath(other_radios_xpath).each { |node| node.remove_attribute('checked') }
    native['checked'] = 'checked'
  end

  def set_checkbox(value) # rubocop:disable Naming/AccessorMethodName
    if value && !native['checked']
      native['checked'] = 'checked'
    elsif !value && native['checked']
      native.remove_attribute('checked')
    end
  end

  def set_range(value) # rubocop:disable Naming/AccessorMethodName
    min, max, step = (native['min'] || 0).to_f, (native['max'] || 100).to_f, (native['step'] || 1).to_f
    value = value.to_f
    value = value.clamp(min, max)
    value = (((value - min) / step).round * step) + min
    native['value'] = value.clamp(min, max)
  end

  def set_input(value) # rubocop:disable Naming/AccessorMethodName
    if text_or_password? && attribute_is_not_blank?(:maxlength)
      # Browser behavior for maxlength="0" is inconsistent, so we stick with
      # Firefox, allowing no input
      value = value.to_s[0...self[:maxlength].to_i]
    end
    if value.is_a?(Array) # Assert multiple attribute is present
      value.each do |val|
        new_native = native.clone
        new_native.remove_attribute('value')
        native.add_next_sibling(new_native)
        new_native['value'] = val.to_s
      end
      native.remove
    else
      native['value'] = value.to_s
    end
  end

  def attribute_is_not_blank?(attribute)
    self[attribute] && !self[attribute].empty?
  end

  def follow_link
    method = self['data-method'] || self['data-turbo-method'] if driver.options[:respect_data_method]
    method ||= :get
    driver.follow(method, self[:href].to_s)
  end

  def click_label
    labelled_control = if native[:for]
      find_xpath("//input[@id='#{native[:for]}']")
    else
      find_xpath('.//input')
    end.first

    labelled_control.set(!labelled_control.checked?) if checkbox_or_radio?(labelled_control)
  end

  def toggle_details(details = nil)
    details ||= native.xpath('.//ancestor-or-self::details').last
    return unless details

    if details.has_attribute?('open')
      details.remove_attribute('open')
    else
      details.set_attribute('open', 'open')
    end
  end

  def link?
    tag_name == 'a' && !self[:href].nil?
  end

  def submits?
    (tag_name == 'input' && %w[submit image].include?(type)) || (tag_name == 'button' && [nil, 'submit'].include?(type))
  end

  def checkable?
    tag_name == 'input' && %w[checkbox radio].include?(type)
  end

protected

  def checkbox_or_radio?(field = self)
    field&.checkbox? || field&.radio?
  end

  def checkbox?
    input_field? && type == 'checkbox'
  end

  def radio?
    input_field? && type == 'radio'
  end

  def text_or_password?
    input_field? && (type == 'text' || type == 'password')
  end

  def input_field?
    tag_name == 'input'
  end

  def textarea?
    tag_name == 'textarea'
  end

  def range?
    input_field? && type == 'range'
  end

  OPTION_OWNER_XPATH = XPath.parent(:optgroup, :select, :datalist).to_s.freeze
  DISABLED_BY_FIELDSET_XPATH = XPath.generate do |x|
    x.parent(:fieldset)[
      XPath.attr(:disabled)
    ] + x.ancestor[
      ~x.self(:legend) |
      x.preceding_sibling(:legend)
    ][
      x.parent(:fieldset)[
        x.attr(:disabled)
      ]
    ]
  end.to_s.freeze
end
