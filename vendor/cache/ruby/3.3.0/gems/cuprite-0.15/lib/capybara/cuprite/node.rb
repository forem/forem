# frozen_string_literal: true

require "forwardable"

module Capybara
  module Cuprite
    class Node < Capybara::Driver::Node
      attr_reader :node

      extend Forwardable

      delegate %i[description] => :node
      delegate %i[browser] => :driver

      def initialize(driver, node)
        super(driver, self)
        @node = node
      end

      def command(name, *args)
        browser.send(name, node, *args)
      rescue Ferrum::NodeNotFoundError => e
        raise ObsoleteNode.new(self, e.response)
      rescue Ferrum::BrowserError => e
        case e.message
        when "Cuprite.MouseEventFailed"
          raise MouseEventFailed.new(self, e.response)
        else
          raise
        end
      end

      def parents
        command(:parents).map do |parent|
          self.class.new(driver, parent)
        end
      end

      def find_xpath(selector)
        find(:xpath, selector)
      end

      def find_css(selector)
        find(:css, selector)
      end

      def find(method, selector)
        command(:find_within, method, selector).map do |node|
          self.class.new(driver, node)
        end
      end

      def all_text
        filter_text(command(:all_text))
      end

      def visible_text
        command(:visible_text).to_s
                              .gsub(/\A[[:space:]&&[^\u00a0]]+/, "")
                              .gsub(/[[:space:]&&[^\u00a0]]+\z/, "")
                              .gsub(/\n+/, "\n")
                              .tr("\u00a0", " ")
      end

      def property(name)
        command(:property, name)
      end

      def [](name)
        # Although the attribute matters, the property is consistent. Return that in
        # preference to the attribute for links and images.
        if (tag_name == "img" && name == "src") ||
           (tag_name == "a" && name == "href")
          # if attribute exists get the property
          return command(:attribute, name) && command(:property, name)
        end

        value = property(name)
        value = command(:attribute, name) if value.nil? || value.is_a?(Hash)

        value
      end

      def attributes
        command(:attributes)
      end

      def value
        command(:value)
      end

      def set(value, options = {})
        warn "Options passed to Node#set but Cuprite doesn't currently support any - ignoring" unless options.empty?

        if tag_name == "input"
          case self[:type]
          when "radio"
            click
          when "checkbox"
            click if value != checked?
          when "file"
            files = value.respond_to?(:to_ary) ? value.to_ary.map(&:to_s) : value.to_s
            command(:select_file, files)
          when "color"
            node.evaluate("this.setAttribute('value', '#{value}')")
          else
            command(:set, value.to_s)
          end
        elsif tag_name == "textarea"
          command(:set, value.to_s)
        elsif self[:isContentEditable]
          command(:delete_text)
          send_keys(value.to_s)
        end
      end

      def select_option
        command(:select, true)
      end

      def unselect_option
        command(:select, false) ||
          raise(Capybara::UnselectNotAllowed, "Cannot unselect option from single select box.")
      end

      def tag_name
        @tag_name ||= description["nodeName"].downcase
      end

      def visible?
        command(:visible?)
      end

      def checked?
        self[:checked]
      end

      def selected?
        !!self[:selected]
      end

      def disabled?
        command(:disabled?)
      end

      def click(keys = [], **options)
        prepare_and_click(:left, __method__, keys, options)
      end

      def right_click(keys = [], **options)
        prepare_and_click(:right, __method__, keys, options)
      end

      def double_click(keys = [], **options)
        prepare_and_click(:double, __method__, keys, options)
      end

      def hover
        command(:hover)
      end

      def drag_to(other, **options)
        options[:steps] ||= 1

        command(:drag, other.node, options[:steps])
      end

      def drag_by(x, y, **options)
        options[:steps] ||= 1

        command(:drag_by, x, y, options[:steps])
      end

      def trigger(event)
        command(:trigger, event)
      end

      def scroll_to(element, location, position = nil)
        if element.is_a?(Node)
          scroll_element_to_location(element, location)
        elsif location.is_a?(Symbol)
          scroll_to_location(location)
        else
          scroll_to_coords(*position)
        end
        self
      end

      def scroll_by(x, y)
        driver.execute_script <<~JS, self, x, y
          var el = arguments[0];
          if (el.scrollBy){
            el.scrollBy(arguments[1], arguments[2]);
          } else {
            el.scrollTop = el.scrollTop + arguments[2];
            el.scrollLeft = el.scrollLeft + arguments[1];
          }
        JS
      end

      def ==(other)
        node == other.native.node
      end

      def send_keys(*keys)
        command(:send_keys, keys)
      end
      alias send_key send_keys

      def path
        command(:path)
      end

      def inspect
        %(#<#{self.class} @node=#{@node.inspect}>)
      end

      # @api private
      def to_json(*)
        JSON.generate(as_json)
      end

      # @api private
      def as_json(*)
        # FIXME: Where is this method used and why attr is called id?
        { ELEMENT: { node: node, id: node.node_id } }
      end

      private

      def prepare_and_click(mode, name, keys, options)
        delay = options[:delay].to_i
        x, y = options.values_at(:x, :y)
        offset = { x: x, y: y, position: options[:offset] || :top }
        command(:before_click, name, keys, offset)
        node.click(mode: mode, keys: keys, offset: offset, delay: delay)
      end

      def filter_text(text)
        text.gsub(/[\u200b\u200e\u200f]/, "")
            .gsub(/[\ \n\f\t\v\u2028\u2029]+/, " ")
            .gsub(/\A[[:space:]&&[^\u00a0]]+/, "")
            .gsub(/[[:space:]&&[^\u00a0]]+\z/, "")
            .tr("\u00a0", " ")
      end

      def scroll_element_to_location(element, location)
        scroll_opts = case location
                      when :top
                        "true"
                      when :bottom
                        "false"
                      when :center
                        "{behavior: 'instant', block: 'center'}"
                      else
                        raise ArgumentError, "Invalid scroll_to location: #{location}"
                      end
        driver.execute_script <<~JS, element
          arguments[0].scrollIntoView(#{scroll_opts})
        JS
      end

      def scroll_to_location(location)
        height = { top: "0",
                   bottom: "arguments[0].scrollHeight",
                   center: "(arguments[0].scrollHeight - arguments[0].clientHeight)/2" }

        driver.execute_script <<~JS, self
          if (arguments[0].scrollTo){
            arguments[0].scrollTo(0, #{height[location]});
          } else {
            arguments[0].scrollTop = #{height[location]};
          }
        JS
      end

      def scroll_to_coords(x, y)
        driver.execute_script <<~JS, self, x, y
          if (arguments[0].scrollTo){
            arguments[0].scrollTo(arguments[1], arguments[2]);
          } else {
            arguments[0].scrollTop = arguments[2];
            arguments[0].scrollLeft = arguments[1];
          }
        JS
      end
    end
  end
end
