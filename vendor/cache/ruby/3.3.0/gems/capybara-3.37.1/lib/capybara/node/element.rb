# frozen_string_literal: true

module Capybara
  module Node
    ##
    #
    # A {Capybara::Node::Element} represents a single element on the page. It is possible
    # to interact with the contents of this element the same as with a document:
    #
    #     session = Capybara::Session.new(:rack_test, my_app)
    #
    #     bar = session.find('#bar')              # from Capybara::Node::Finders
    #     bar.select('Baz', from: 'Quox')      # from Capybara::Node::Actions
    #
    # {Capybara::Node::Element} also has access to HTML attributes and other properties of the
    # element:
    #
    #      bar.value
    #      bar.text
    #      bar[:title]
    #
    # @see Capybara::Node
    #
    class Element < Base
      def initialize(session, base, query_scope, query)
        super(session, base)
        @query_scope = query_scope
        @query = query
        @allow_reload = false
        @query_idx = nil
      end

      def allow_reload!(idx = nil)
        @query_idx = idx
        @allow_reload = true
      end

      ##
      #
      # @return [Object]    The native element from the driver, this allows access to driver specific methods
      #
      def native
        synchronize { base.native }
      end

      ##
      #
      # Retrieve the text of the element. If {Capybara.configure ignore_hidden_elements}
      # is `true`, which it is by default, then this will return only text
      # which is visible. The exact semantics of this may differ between
      # drivers, but generally any text within elements with `display:none` is
      # ignored. This behaviour can be overridden by passing `:all` to this
      # method.
      #
      # @param type [:all, :visible]  Whether to return only visible or all text
      # @return [String]              The text of the element
      #
      def text(type = nil, normalize_ws: false)
        type ||= :all unless session_options.ignore_hidden_elements || session_options.visible_text_only
        txt = synchronize { type == :all ? base.all_text : base.visible_text }
        normalize_ws ? txt.gsub(/[[:space:]]+/, ' ').strip : txt
      end

      ##
      #
      # Retrieve the given attribute.
      #
      #     element[:title] # => HTML title attribute
      #
      # @param  [Symbol] attribute     The attribute to retrieve
      # @return [String]               The value of the attribute
      #
      def [](attribute)
        synchronize { base[attribute] }
      end

      ##
      #
      # Retrieve the given CSS styles.
      #
      #     element.style('color', 'font-size') # => Computed values of CSS 'color' and 'font-size' styles
      #
      # @param [Array<String>] styles   Names of the desired CSS properties
      # @return [Hash]            Hash of the CSS property names to computed values
      #
      def style(*styles)
        styles = styles.flatten.map(&:to_s)
        raise ArgumentError, 'You must specify at least one CSS style' if styles.empty?

        begin
          synchronize { base.style(styles) }
        rescue NotImplementedError => e
          begin
            evaluate_script(STYLE_SCRIPT, *styles)
          rescue Capybara::NotSupportedByDriverError
            raise e
          end
        end
      end

      ##
      #
      # @return [String]    The value of the form element
      #
      def value
        synchronize { base.value }
      end

      ##
      #
      # Set the value of the form element to the given value.
      #
      # @param [String] value    The new value
      # @param [Hash] options    Driver specific options for how to set the value. Take default values from {Capybara.configure default_set_options}.
      #
      # @return [Capybara::Node::Element]  The element
      def set(value, **options)
        if ENV.fetch('CAPYBARA_THOROUGH', nil) && readonly?
          raise Capybara::ReadOnlyElementError, "Attempt to set readonly element with value: #{value}"
        end

        options = session_options.default_set_options.to_h.merge(options)
        synchronize { base.set(value, **options) }
        self
      end

      ##
      #
      # Select this node if it is an option element inside a select tag.
      #
      # @!macro action_waiting_behavior
      #   If the driver dynamic pages (JS) and the element is currently non-interactable, this method will
      #   continuously retry the action until either the element becomes interactable or the maximum
      #   wait time expires.
      #
      #   @param [false, Numeric] wait
      #     Maximum time to wait for the action to succeed. Defaults to {Capybara.configure default_max_wait_time}.
      # @return [Capybara::Node::Element]  The element
      def select_option(wait: nil)
        synchronize(wait) { base.select_option }
        self
      end

      ##
      #
      # Unselect this node if it is an option element inside a multiple select tag.
      #
      # @macro action_waiting_behavior
      # @return [Capybara::Node::Element]  The element
      def unselect_option(wait: nil)
        synchronize(wait) { base.unselect_option }
        self
      end

      ##
      #
      # Click the Element.
      #
      # @macro action_waiting_behavior
      # @!macro click_modifiers
      #   Both x: and y: must be specified if an offset is wanted, if not specified the click will occur at the middle of the element.
      #   @overload $0(*modifier_keys, wait: nil, **offset)
      #     @param *modifier_keys [:alt, :control, :meta, :shift] ([]) Keys to be held down when clicking
      #     @option options [Integer] x  X coordinate to offset the click location. If {Capybara.configure w3c_click_offset} is `true` the
      #       offset will be from the element center, otherwise it will be from the top left corner of the element
      #     @option options [Integer] y  Y coordinate to offset the click location. If {Capybara.configure w3c_click_offset} is `true` the
      #       offset will be from the element center, otherwise it will be from the top left corner of the element
      # @option options [Float] delay  Delay between the mouse down and mouse up events in seconds (0)
      # @return [Capybara::Node::Element]  The element
      def click(*keys, **options)
        perform_click_action(keys, **options) do |k, opts|
          base.click(k, **opts)
        end
      end

      ##
      #
      # Right Click the Element.
      #
      # @macro action_waiting_behavior
      # @macro click_modifiers
      # @option options [Float] delay  Delay between the mouse down and mouse up events in seconds (0)
      # @return [Capybara::Node::Element]  The element
      def right_click(*keys, **options)
        perform_click_action(keys, **options) do |k, opts|
          base.right_click(k, **opts)
        end
      end

      ##
      #
      # Double Click the Element.
      #
      # @macro action_waiting_behavior
      # @macro click_modifiers
      # @return [Capybara::Node::Element]  The element
      def double_click(*keys, **options)
        perform_click_action(keys, **options) do |k, opts|
          base.double_click(k, **opts)
        end
      end

      ##
      #
      # Send Keystrokes to the Element.
      #
      # @overload send_keys(keys, ...)
      #   @param keys [String, Symbol, Array<String,Symbol>]
      #
      # Examples:
      #
      #     element.send_keys "foo"                     #=> value: 'foo'
      #     element.send_keys "tet", :left, "s"         #=> value: 'test'
      #     element.send_keys [:control, 'a'], :space   #=> value: ' ' - assuming ctrl-a selects all contents
      #
      # Symbols supported for keys:
      # * :cancel
      # * :help
      # * :backspace
      # * :tab
      # * :clear
      # * :return
      # * :enter
      # * :shift
      # * :control
      # * :alt
      # * :pause
      # * :escape
      # * :space
      # * :page_up
      # * :page_down
      # * :end
      # * :home
      # * :left
      # * :up
      # * :right
      # * :down
      # * :insert
      # * :delete
      # * :semicolon
      # * :equals
      # * :numpad0
      # * :numpad1
      # * :numpad2
      # * :numpad3
      # * :numpad4
      # * :numpad5
      # * :numpad6
      # * :numpad7
      # * :numpad8
      # * :numpad9
      # * :multiply      - numeric keypad *
      # * :add           - numeric keypad +
      # * :separator     - numeric keypad 'separator' key ??
      # * :subtract      - numeric keypad -
      # * :decimal       - numeric keypad .
      # * :divide        - numeric keypad /
      # * :f1
      # * :f2
      # * :f3
      # * :f4
      # * :f5
      # * :f6
      # * :f7
      # * :f8
      # * :f9
      # * :f10
      # * :f11
      # * :f12
      # * :meta
      # * :command      - alias of :meta
      #
      # @return [Capybara::Node::Element]  The element
      def send_keys(*args)
        synchronize { base.send_keys(*args) }
        self
      end

      ##
      #
      # Hover on the Element.
      #
      # @return [Capybara::Node::Element]  The element
      def hover
        synchronize { base.hover }
        self
      end

      ##
      #
      # @return [String]      The tag name of the element
      #
      def tag_name
        # Element type is immutable so cache it
        @tag_name ||= initial_cache[:tag_name] || synchronize { base.tag_name }
      end

      ##
      #
      # Whether or not the element is visible. Not all drivers support CSS, so
      # the result may be inaccurate.
      #
      # @return [Boolean]     Whether the element is visible
      #
      def visible?
        synchronize { base.visible? }
      end

      ##
      #
      # Whether or not the element is currently in the viewport and it (or descendants)
      # would be considered clickable at the elements center point.
      #
      # @return [Boolean]     Whether the elements center is obscured.
      #
      def obscured?
        synchronize { base.obscured? }
      end

      ##
      #
      # Whether or not the element is checked.
      #
      # @return [Boolean]     Whether the element is checked
      #
      def checked?
        synchronize { base.checked? }
      end

      ##
      #
      # Whether or not the element is selected.
      #
      # @return [Boolean]     Whether the element is selected
      #
      def selected?
        synchronize { base.selected? }
      end

      ##
      #
      # Whether or not the element is disabled.
      #
      # @return [Boolean]     Whether the element is disabled
      #
      def disabled?
        synchronize { base.disabled? }
      end

      ##
      #
      # Whether or not the element is readonly.
      #
      # @return [Boolean]     Whether the element is readonly
      #
      def readonly?
        synchronize { base.readonly? }
      end

      ##
      #
      # Whether or not the element supports multiple results.
      #
      # @return [Boolean]     Whether the element supports multiple results.
      #
      def multiple?
        synchronize { base.multiple? }
      end

      ##
      #
      # An XPath expression describing where on the page the element can be found.
      #
      # @return [String]      An XPath expression
      #
      def path
        synchronize { base.path }
      end

      def rect
        synchronize { base.rect }
      end

      ##
      #
      # Trigger any event on the current element, for example mouseover or focus
      # events. Not supported with the Selenium driver, and SHOULDN'T BE USED IN TESTING unless you
      # fully understand why you're using it, that it can allow actions a user could never
      # perform, and that it may completely invalidate your test.
      #
      # @param [String] event       The name of the event to trigger
      #
      # @return [Capybara::Node::Element]  The element
      def trigger(event)
        synchronize { base.trigger(event) }
        self
      end

      ##
      #
      # Drag the element to the given other element.
      #
      #     source = page.find('#foo')
      #     target = page.find('#bar')
      #     source.drag_to(target)
      #
      # @param [Capybara::Node::Element] node     The element to drag to
      # @param [Hash] options  Driver specific options for dragging. May not be supported by all drivers.
      # @option options [Numeric] :delay   (0.05) When using Chrome/Firefox with Selenium and HTML5 dragging this is the number
      #                                    of seconds between each stage of the drag.
      # @option options [Boolean] :html5   When using Chrome/Firefox with Selenium enables to force the use of HTML5
      #                                    (true) or legacy (false) dragging. If not specified the driver will attempt to
      #                                    detect the correct method to use.
      # @option options [Array<Symbol>,Symbol] :drop_modifiers   Modifier keys which should be held while the dragged element is dropped.
      #
      #
      # @return [Capybara::Node::Element]  The dragged element
      def drag_to(node, **options)
        synchronize { base.drag_to(node.base, **options) }
        self
      end

      ##
      #
      # Drop items on the current element.
      #
      #     target = page.find('#foo')
      #     target.drop('/some/path/file.csv')
      #
      # @overload drop(path, ...)
      #   @param [String, #to_path] path Location of the file to drop on the element
      #
      # @overload drop(strings, ...)
      #   @param [Hash] strings A hash of type to data to be dropped - `{ "text/url" => "https://www.google.com" }`
      #
      # @return [Capybara::Node::Element]  The element
      def drop(*args)
        options = args.map { |arg| arg.respond_to?(:to_path) ? arg.to_path : arg }
        synchronize { base.drop(*options) }
        self
      end

      ##
      #
      # Scroll the page or element.
      #
      # @overload scroll_to(position, offset: [0,0])
      #   Scroll the page or element to its top, bottom or middle.
      #   @param [:top, :bottom, :center, :current] position
      #   @param [[Integer, Integer]] offset
      #
      # @overload scroll_to(element, align: :top)
      #   Scroll the page or current element until the given element is aligned at the top, bottom, or center of it.
      #   @param [Capybara::Node::Element] element   The element to be scrolled into view
      #   @param [:top, :bottom, :center] align Where to align the element being scrolled into view with relation to the current page/element if possible
      #
      # @overload scroll_to(x,y)
      #   @param [Integer] x    Horizontal scroll offset
      #   @param [Integer] y    Vertical scroll offset
      #
      # @return [Capybara::Node::Element]  The element
      def scroll_to(pos_or_el_or_x, y = nil, align: :top, offset: nil)
        case pos_or_el_or_x
        when Symbol
          synchronize { base.scroll_to(nil, pos_or_el_or_x) } unless pos_or_el_or_x == :current
        when Capybara::Node::Element
          synchronize { base.scroll_to(pos_or_el_or_x.base, align) }
        else
          synchronize { base.scroll_to(nil, nil, [pos_or_el_or_x, y]) }
        end
        synchronize { base.scroll_by(*offset) } unless offset.nil?
        self
      end

      ##
      #
      # Return the shadow_root for the current element
      #
      # @return [Capybara::Node::Element]  The shadow root

      def shadow_root
        root = synchronize { base.shadow_root }
        root && Capybara::Node::Element.new(session, root, nil, nil)
      end

      ##
      #
      # Execute the given JS in the context of the element not returning a result. This is useful for scripts that return
      # complex objects, such as jQuery statements. {#execute_script} should be used over
      # {#evaluate_script} whenever a result is not expected or needed. `this` in the script will refer to the element this is called on.
      #
      # @param [String] script   A string of JavaScript to execute
      # @param args  Optional arguments that will be passed to the script. Driver support for this is optional and types of objects supported may differ between drivers
      #
      def execute_script(script, *args)
        session.execute_script(<<~JS, self, *args)
          (function (){
            #{script}
          }).apply(arguments[0], Array.prototype.slice.call(arguments,1));
        JS
      end

      ##
      #
      # Evaluate the given JS in the context of the element and return the result. Be careful when using this with
      # scripts that return complex objects, such as jQuery statements. {#execute_script} might
      # be a better alternative. `this` in the script will refer to the element this is called on.
      #
      # @param  [String] script   A string of JavaScript to evaluate
      # @return [Object]          The result of the evaluated JavaScript (may be driver specific)
      #
      def evaluate_script(script, *args)
        session.evaluate_script(<<~JS, self, *args)
          (function(){
            return #{script.strip}
          }).apply(arguments[0], Array.prototype.slice.call(arguments,1));
        JS
      end

      ##
      #
      # Evaluate the given JavaScript in the context of the element and obtain the result from a
      # callback function which will be passed as the last argument to the script. `this` in the
      # script will refer to the element this is called on.
      #
      # @param  [String] script   A string of JavaScript to evaluate
      # @return [Object]          The result of the evaluated JavaScript (may be driver specific)
      #
      def evaluate_async_script(script, *args)
        session.evaluate_async_script(<<~JS, self, *args)
          (function (){
            #{script}
          }).apply(arguments[0], Array.prototype.slice.call(arguments,1));
        JS
      end

      ##
      #
      # Toggle the elements background color between white and black for a period of time.
      #
      # @return [Capybara::Node::Element]  The element
      def flash
        execute_script(<<~JS, 100)
          async function flash(el, delay){
            var old_bg = el.style.backgroundColor;
            var colors = ["black", "white"];
            for(var i=0; i<20; i++){
              el.style.backgroundColor = colors[i % colors.length];
              await new Promise(resolve => setTimeout(resolve, delay));
            }
            el.style.backgroundColor = old_bg;
          }
          flash(this, arguments[0]);
        JS

        self
      end

      # @api private
      def reload
        return self unless @allow_reload

        begin
          reloaded = @query.resolve_for(query_scope ? query_scope.reload : session)[@query_idx.to_i]
          @base = reloaded.base if reloaded
        rescue StandardError => e
          raise e unless catch_error?(e)
        end
        self
      end

      ##
      #
      # A human-readable representation of the element.
      #
      # @return [String]  A string representation
      def inspect
        %(#<Capybara::Node::Element tag="#{base.tag_name}" path="#{base.path}">)
      rescue NotSupportedByDriverError
        %(#<Capybara::Node::Element tag="#{base.tag_name}">)
      rescue *session.driver.invalid_element_errors
        %(Obsolete #<Capybara::Node::Element>)
      end

      # @api private
      def initial_cache
        base.respond_to?(:initial_cache) ? base.initial_cache : {}
      end

      STYLE_SCRIPT = <<~JS
        (function(){
          var s = window.getComputedStyle(this);
          var result = {};
          for (var i = arguments.length; i--; ) {
            var property_name = arguments[i];
            result[property_name] = s.getPropertyValue(property_name);
          }
          return result;
        }).apply(this, arguments)
      JS

    private

      def perform_click_action(keys, wait: nil, **options)
        raise ArgumentError, 'You must specify both x: and y: for a click offset' if nil ^ options[:x] ^ options[:y]

        options[:offset] ||= :center if session_options.w3c_click_offset
        synchronize(wait) { yield keys, options }
        self
      end
    end
  end
end
