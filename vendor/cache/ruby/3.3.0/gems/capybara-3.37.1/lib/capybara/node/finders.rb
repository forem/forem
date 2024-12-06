# frozen_string_literal: true

module Capybara
  module Node
    module Finders
      ##
      #
      # Find an {Capybara::Node::Element} based on the given arguments. {#find} will raise an error if the element
      # is not found.
      #
      #     page.find('#foo').find('.bar')
      #     page.find(:xpath, './/div[contains(., "bar")]')
      #     page.find('li', text: 'Quox').click_link('Delete')
      #
      # @param (see #all)
      #
      # @macro waiting_behavior
      #
      # @!macro system_filters
      #   @option options [String, Regexp] text      Only find elements which contain this text or match this regexp
      #   @option options [String, Regexp, String] exact_text
      #     When String the elements contained text must match exactly, when Boolean controls whether the `text` option must match exactly.
      #     Defaults to {Capybara.configure exact_text}.
      #   @option options [Boolean] normalize_ws
      #     Whether the `text`/`exact_text` options are compared against element text with whitespace normalized or as returned by the driver.
      #     Defaults to {Capybara.configure default_normalize_ws}.
      #   @option options [Boolean, Symbol] visible
      #     Only find elements with the specified visibility. Defaults to behavior indicated by {Capybara.configure ignore_hidden_elements}.
      #       * true - only finds visible elements.
      #       * false - finds invisible _and_ visible elements.
      #       * :all - same as false; finds visible and invisible elements.
      #       * :hidden - only finds invisible elements.
      #       * :visible - same as true; only finds visible elements.
      #   @option options [Boolean] obscured  Only find elements with the specified obscured state:
      #                                       * true - only find elements whose centerpoint is not in the viewport or is obscured by another non-descendant element.
      #                                       * false - only find elements whose centerpoint is in the viewport and is not obscured by other non-descendant elements.
      #   @option options [String, Regexp]  id           Only find elements with an id that matches the value passed
      #   @option options [String, Array<String>, Regexp] class  Only find elements with matching class/classes.
      #                                            * Absence of a class can be checked by prefixing the class name with `!`
      #                                            * If you need to check for existence of a class name that starts with `!` then prefix with `!!`
      #
      #                                                class:['a', '!b', '!!!c'] # limit to elements with class 'a' and '!c' but not class 'b'
      #
      #   @option options [String, Regexp, Hash] style  Only find elements with matching style. String and Regexp will be checked against text of the elements `style` attribute, while a Hash will be compared against the elements full style
      #   @option options [Boolean] exact            Control whether `is` expressions in the given XPath match exactly or partially. Defaults to {Capybara.configure exact}.
      #   @option options [Symbol] match        The matching strategy to use. Defaults to {Capybara.configure match}.
      #
      # @return [Capybara::Node::Element]      The found element
      # @raise  [Capybara::ElementNotFound]    If the element can't be found before time expires
      #
      def find(*args, **options, &optional_filter_block)
        options[:session_options] = session_options
        count_options = options.slice(*Capybara::Queries::BaseQuery::COUNT_KEYS)
        unless count_options.empty?
          Capybara::Helpers.warn(
            "'find' does not support count options (#{count_options}) ignoring. " \
            "Called from: #{Capybara::Helpers.filter_backtrace(caller)}"
          )
        end
        synced_resolve Capybara::Queries::SelectorQuery.new(*args, **options, &optional_filter_block)
      end

      ##
      #
      # Find an {Capybara::Node::Element} based on the given arguments that is also an ancestor of the element called on.
      # {#ancestor} will raise an error if the element is not found.
      #
      # {#ancestor} takes the same options as {#find}.
      #
      #     element.ancestor('#foo').find('.bar')
      #     element.ancestor(:xpath, './/div[contains(., "bar")]')
      #     element.ancestor('ul', text: 'Quox').click_link('Delete')
      #
      # @param (see #find)
      #
      # @macro waiting_behavior
      #
      # @return [Capybara::Node::Element]      The found element
      # @raise  [Capybara::ElementNotFound]    If the element can't be found before time expires
      #
      def ancestor(*args, **options, &optional_filter_block)
        options[:session_options] = session_options
        synced_resolve Capybara::Queries::AncestorQuery.new(*args, **options, &optional_filter_block)
      end

      ##
      #
      # Find an {Capybara::Node::Element} based on the given arguments that is also a sibling of the element called on.
      # {#sibling} will raise an error if the element is not found.
      #
      # {#sibling} takes the same options as {#find}.
      #
      #     element.sibling('#foo').find('.bar')
      #     element.sibling(:xpath, './/div[contains(., "bar")]')
      #     element.sibling('ul', text: 'Quox').click_link('Delete')
      #
      # @param (see #find)
      #
      # @macro waiting_behavior
      #
      # @return [Capybara::Node::Element]      The found element
      # @raise  [Capybara::ElementNotFound]    If the element can't be found before time expires
      #
      def sibling(*args, **options, &optional_filter_block)
        options[:session_options] = session_options
        synced_resolve Capybara::Queries::SiblingQuery.new(*args, **options, &optional_filter_block)
      end

      ##
      #
      # Find a form field on the page. The field can be found by its name, id or label text.
      #
      # @overload find_field([locator], **options)
      #   @param [String] locator             name, id, {Capybara.configure test_id} attribute, placeholder or text of associated label element
      #
      #   @macro waiting_behavior
      #
      #
      #   @option options [Boolean] checked       Match checked field?
      #   @option options [Boolean] unchecked     Match unchecked field?
      #   @option options [Boolean, Symbol] disabled (false)  Match disabled field?
      #                                                       * true - only finds a disabled field
      #                                                       * false - only finds an enabled field
      #                                                       * :all - finds either an enabled or disabled field
      #   @option options [Boolean] readonly      Match readonly field?
      #   @option options [String, Regexp] with   Value of field to match on
      #   @option options [String] type           Type of field to match on
      #   @option options [Boolean] multiple      Match fields that can have multiple values?
      #   @option options [String, Regexp] id     Match fields that match the id attribute
      #   @option options [String] name           Match fields that match the name attribute
      #   @option options [String] placeholder    Match fields that match the placeholder attribute
      #   @option options [String, Array<String>, Regexp] class Match fields that match the class(es) passed
      # @return [Capybara::Node::Element]   The found element
      #
      def find_field(locator = nil, **options, &optional_filter_block)
        find(:field, locator, **options, &optional_filter_block)
      end

      ##
      #
      # Find a link on the page. The link can be found by its id or text.
      #
      # @overload find_link([locator], **options)
      #   @param [String] locator            id, {Capybara.configure test_id} attribute, title, text, or alt of enclosed img element
      #
      #   @macro waiting_behavior
      #
      #   @option options [String,Regexp,nil] href    Value to match against the links href, if `nil` finds link placeholders (`<a>` elements with no href attribute), if `false` ignores the href
      #   @option options [String, Regexp] id         Match links with the id provided
      #   @option options [String] title              Match links with the title provided
      #   @option options [String] alt                Match links with a contained img element whose alt matches
      #   @option options [String, Array<String>, Regexp] class    Match links that match the class(es) provided
      # @return [Capybara::Node::Element]   The found element
      #
      def find_link(locator = nil, **options, &optional_filter_block)
        find(:link, locator, **options, &optional_filter_block)
      end

      ##
      #
      # Find a button on the page.
      # This can be any `<input>` element of type submit, reset, image, button or it can be a
      # `<button>` element. All buttons can be found by their id, name, {Capybara.configure test_id} attribute, value, or title.
      # `<button>` elements can also be found by their text content, and image `<input>` elements by their alt attribute.
      #
      # @overload find_button([locator], **options)
      #   @param [String] locator            id, name, {Capybara.configure test_id} attribute, value, title, text content, alt of image
      #
      #   @macro waiting_behavior
      #
      #   @option options [Boolean, Symbol] disabled (false)  Match disabled button?
      #                                                       * true - only finds a disabled button
      #                                                       * false - only finds an enabled button
      #                                                       * :all - finds either an enabled or disabled button
      #   @option options [String, Regexp] id                 Match buttons with the id provided
      #   @option options [String] name                       Match buttons with the name provided
      #   @option options [String] title                      Match buttons with the title provided
      #   @option options [String] value                      Match buttons with the value provided
      #   @option options [String, Array<String>, Regexp] class    Match buttons that match the class(es) provided
      # @return [Capybara::Node::Element]   The found element
      #
      def find_button(locator = nil, **options, &optional_filter_block)
        find(:button, locator, **options, &optional_filter_block)
      end

      ##
      #
      # Find a element on the page, given its id.
      #
      # @macro waiting_behavior
      #
      # @param [String] id                  id of element
      #
      # @return [Capybara::Node::Element]   The found element
      #
      def find_by_id(id, **options, &optional_filter_block)
        find(:id, id, **options, &optional_filter_block)
      end

      ##
      # @!method all([kind = Capybara.default_selector], locator = nil, **options)
      #
      # Find all elements on the page matching the given selector
      # and options.
      #
      # Both XPath and CSS expressions are supported, but Capybara
      # does not try to automatically distinguish between them. The
      # following statements are equivalent:
      #
      #     page.all(:css, 'a#person_123')
      #     page.all(:xpath, './/a[@id="person_123"]')
      #
      # If the type of selector is left out, Capybara uses
      # {Capybara.configure default_selector}. It's set to `:css` by default.
      #
      #     page.all("a#person_123")
      #
      #     Capybara.default_selector = :xpath
      #     page.all('.//a[@id="person_123"]')
      #
      # The set of found elements can further be restricted by specifying
      # options. It's possible to select elements by their text or visibility:
      #
      #     page.all('a', text: 'Home')
      #     page.all('#menu li', visible: true)
      #
      # By default Capybara's waiting behavior will wait up to {Capybara.configure default_max_wait_time}
      # seconds for matching elements to be available and then return an empty result if none
      # are available. It is possible to set expectations on the number of results located and
      # Capybara will raise an exception if the number of elements located don't satisfy the
      # specified conditions. The expectations can be set using:
      #
      #     page.assert_selector('p#foo', count: 4)
      #     page.assert_selector('p#foo', maximum: 10)
      #     page.assert_selector('p#foo', minimum: 1)
      #     page.assert_selector('p#foo', between: 1..10)
      #
      # @param [Symbol] kind                       Optional selector type (:css, :xpath, :field, etc.). Defaults to {Capybara.configure default_selector}.
      # @param [String] locator                    The locator for the specified selector
      # @macro system_filters
      # @macro waiting_behavior
      # @option options [Integer] count            Exact number of matches that are expected to be found
      # @option options [Integer] maximum          Maximum number of matches that are expected to be found
      # @option options [Integer] minimum          Minimum number of matches that are expected to be found
      # @option options [Range]   between          Number of matches found must be within the given range
      # @option options [Boolean] allow_reload     Beta feature - May be removed in any version.
      #   When `true` allows elements to be reloaded if they become stale. This is an advanced behavior and should only be used
      #   if you fully understand the potential ramifications. The results can be confusing on dynamic pages. Defaults to `false`
      # @overload all([kind = Capybara.default_selector], locator = nil, **options)
      # @overload all([kind = Capybara.default_selector], locator = nil, **options, &filter_block)
      #   @yieldparam element [Capybara::Node::Element]  The element being considered for inclusion in the results
      #   @yieldreturn [Boolean]                     Should the element be considered in the results?
      # @return [Capybara::Result]                   A collection of found elements
      # @raise [Capybara::ExpectationNotMet]         The number of elements found doesn't match the specified conditions
      def all(*args, allow_reload: false, **options, &optional_filter_block)
        minimum_specified = options_include_minimum?(options)
        options = { minimum: 1 }.merge(options) unless minimum_specified
        options[:session_options] = session_options
        query = Capybara::Queries::SelectorQuery.new(*args, **options, &optional_filter_block)
        result = nil
        begin
          synchronize(query.wait) do
            result = query.resolve_for(self)
            result.allow_reload! if allow_reload
            raise Capybara::ExpectationNotMet, result.failure_message unless result.matches_count?

            result
          end
        rescue Capybara::ExpectationNotMet
          raise if minimum_specified || (result.compare_count == 1)

          Result.new([], nil)
        end
      end
      alias_method :find_all, :all

      ##
      #
      # Find the first element on the page matching the given selector
      # and options. By default {#first} will wait up to {Capybara.configure default_max_wait_time}
      # seconds for matching elements to appear and then raise an error if no matching
      # element is found, or `nil` if the provided count options allow for empty results.
      #
      # @overload first([kind], locator, options)
      #   @param [Symbol] kind                       The type of selector
      #   @param [String] locator                    The selector
      #   @param [Hash] options                      Additional options; see {#all}
      # @return [Capybara::Node::Element]            The found element or nil
      # @raise  [Capybara::ElementNotFound]          If element(s) matching the provided options can't be found before time expires
      #
      def first(*args, **options, &optional_filter_block)
        options = { minimum: 1 }.merge(options) unless options_include_minimum?(options)
        all(*args, **options, &optional_filter_block).first
      end

    private

      def synced_resolve(query)
        synchronize(query.wait) do
          if prefer_exact?(query)
            result = query.resolve_for(self, true)
            result = query.resolve_for(self, false) if result.empty? && query.supports_exact? && !query.exact?
          else
            result = query.resolve_for(self)
          end

          if ambiguous?(query, result)
            raise Capybara::Ambiguous, "Ambiguous match, found #{result.size} elements matching #{query.applied_description}"
          end
          raise Capybara::ElementNotFound, "Unable to find #{query.applied_description}" if result.empty?

          result.first
        end.tap(&:allow_reload!)
      end

      def ambiguous?(query, result)
        %i[one smart].include?(query.match) && (result.size > 1)
      end

      def prefer_exact?(query)
        %i[smart prefer_exact].include?(query.match)
      end

      def options_include_minimum?(opts)
        %i[count minimum between].any? { |key| opts.key?(key) }
      end

      def parent
        first(:xpath, './parent::*', minimum: 0)
      end
    end
  end
end
