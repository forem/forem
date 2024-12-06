# frozen_string_literal: true

module Capybara
  module Node
    ##
    #
    # A {Capybara::Node::Simple} is a simpler version of {Capybara::Node::Base} which
    # includes only {Capybara::Node::Finders} and {Capybara::Node::Matchers} and does
    # not include {Capybara::Node::Actions}. This type of node is returned when
    # using {Capybara.string}.
    #
    # It is useful in that it does not require a session, an application or a driver,
    # but can still use Capybara's finders and matchers on any string that contains HTML.
    #
    class Simple
      include Capybara::Node::Finders
      include Capybara::Node::Matchers
      include Capybara::Node::DocumentMatchers

      attr_reader :native

      def initialize(native)
        native = Capybara::HTML(native) if native.is_a?(String)
        @native = native
      end

      ##
      #
      # @return [String]    The text of the element
      #
      def text(_type = nil, normalize_ws: false)
        txt = native.text
        normalize_ws ? txt.gsub(/[[:space:]]+/, ' ').strip : txt
      end

      ##
      #
      # Retrieve the given attribute
      #
      #     element[:title] # => HTML title attribute
      #
      # @param  [Symbol] name  The attribute name to retrieve
      # @return [String]       The value of the attribute
      #
      def [](name)
        attr_name = name.to_s
        if attr_name == 'value'
          value
        elsif (tag_name == 'input') && (native[:type] == 'checkbox') && (attr_name == 'checked')
          native['checked'] == 'checked'
        else
          native[attr_name]
        end
      end

      ##
      #
      # @return [String]      The tag name of the element
      #
      def tag_name
        native.node_name
      end

      ##
      #
      # An XPath expression describing where on the page the element can be found
      #
      # @return [String]      An XPath expression
      #
      def path
        native.path
      end

      ##
      #
      # @return [String]    The value of the form element
      #
      def value
        if tag_name == 'textarea'
          native['_capybara_raw_value']
        elsif tag_name == 'select'
          selected_options = find_xpath('.//option[@selected]')
          if multiple?
            selected_options.map(&method(:option_value))
          else
            option_value(selected_options.first || find_xpath('.//option').first)
          end
        elsif tag_name == 'input' && %w[radio checkbox].include?(native[:type])
          native[:value] || 'on'
        else
          native[:value]
        end
      end

      ##
      #
      # Whether or not the element is visible. Does not support CSS, so
      # the result may be inaccurate.
      #
      # @param  [Boolean] check_ancestors  Whether to inherit visibility from ancestors
      # @return [Boolean]     Whether the element is visible
      #
      def visible?(check_ancestors = true) # rubocop:disable Style/OptionalBooleanParameter
        return false if (tag_name == 'input') && (native[:type] == 'hidden')
        return false if tag_name == 'template'

        if check_ancestors
          !find_xpath(VISIBILITY_XPATH)
        else
          # No need for an xpath if only checking the current element
          !(native.key?('hidden') ||
            /display:\s?none/.match?(native[:style] || '') ||
            %w[script head style].include?(tag_name))
        end
      end

      ##
      #
      # Whether or not the element is checked.
      #
      # @return [Boolean]     Whether the element is checked
      #
      def checked?
        native.has_attribute?('checked')
      end

      ##
      #
      # Whether or not the element is disabled.
      #
      # @return [Boolean]     Whether the element is disabled
      def disabled?
        native.has_attribute?('disabled') &&
          %w[button input select textarea optgroup option menuitem fieldset].include?(tag_name)
      end

      ##
      #
      # Whether or not the element is selected.
      #
      # @return [Boolean]     Whether the element is selected
      #
      def selected?
        native.has_attribute?('selected')
      end

      def multiple?
        native.has_attribute?('multiple')
      end

      def readonly?
        native.has_attribute?('readonly')
      end

      def synchronize(_seconds = nil)
        yield # simple nodes don't need to wait
      end

      def allow_reload!(*)
        # no op
      end

      ##
      #
      # @return [String]     The title of the document
      def title
        native.title
      end

      def inspect
        %(#<Capybara::Node::Simple tag="#{tag_name}" path="#{path}">)
      end

      # @api private
      def find_css(css, **_options)
        native.css(css)
      end

      # @api private
      def find_xpath(xpath, **_options)
        native.xpath(xpath)
      end

      # @api private
      def session_options
        Capybara.session_options
      end

      # @api private
      def initial_cache
        {}
      end

      def ==(other)
        eql?(other) || (other.respond_to?(:native) && native == other.native)
      end

    private

      def option_value(option)
        return nil if option.nil?

        option[:value] || option.content
      end

      VISIBILITY_XPATH = XPath.generate do |x|
        x.ancestor_or_self[
          x.attr(:style)[x.contains('display:none') | x.contains('display: none')] |
          x.attr(:hidden) |
          x.qname.one_of('script', 'head') |
          (~x.self(:summary) & XPath.parent(:details)[!XPath.attr(:open)])
        ].boolean
      end.to_s.freeze
    end
  end
end
