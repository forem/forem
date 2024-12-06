# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Helps parsing css selector.
      # @api private
      module CssSelector
        module_function

        # @param selector [String]
        # @return [String]
        # @example
        #   id('#some-id') # => some-id
        #   id('.some-cls') # => nil
        #   id('#some-id.cls') # => some-id
        def id(selector)
          return unless id?(selector)

          selector.delete('#').gsub(selector.scan(/[^\\]([>,+~.].*)/).join, '')
        end

        # @param selector [String]
        # @return [Boolean]
        # @example
        #   id?('#some-id') # => true
        #   id?('.some-cls') # => false
        def id?(selector)
          selector.start_with?('#')
        end

        # @param selector [String]
        # @return [Array<String>]
        # @example
        #   classes('#some-id') # => []
        #   classes('.some-cls') # => ['some-cls']
        #   classes('#some-id.some-cls') # => ['some-cls']
        #   classes('#some-id.cls1.cls2') # => ['cls1', 'cls2']
        def classes(selector)
          selector.scan(/\.([\w-]*)/).flatten
        end

        # @param selector [String]
        # @return [Boolean]
        # @example
        #   attribute?('[attribute]') # => true
        #   attribute?('attribute') # => false
        def attribute?(selector)
          selector.start_with?('[')
        end

        # @param selector [String]
        # @return [Array<String>]
        # @example
        #   attributes('a[foo-bar_baz]') # => {"foo-bar_baz=>nil}
        #   attributes('button[foo][bar=baz]') # => {"foo"=>nil, "bar"=>"'baz'"}
        #   attributes('table[foo=bar]') # => {"foo"=>"'bar'"}
        #   attributes('[foo="bar[baz][qux]"]') # => {"foo"=>"'bar[baz][qux]'"}
        def attributes(selector)
          CssAttributesParser.new(selector).parse
        end

        # @param selector [String]
        # @return [Array<String>]
        # @example
        #   pseudo_classes('button:not([disabled])') # => ['not()']
        #   pseudo_classes('a:enabled:not([valid])') # => ['enabled', 'not()']
        def pseudo_classes(selector)
          # Attributes must be excluded or else the colon in the `href`s URL
          # will also be picked up as pseudo classes.
          # "a:not([href='http://example.com']):enabled" => "a:not():enabled"
          ignored_attribute = selector.gsub(/\[.*?\]/, '')
          # "a:not():enabled" => ["not()", "enabled"]
          ignored_attribute.scan(/:([^:]*)/).flatten
        end

        # @param selector [String]
        # @return [Boolean]
        # @example
        #   multiple_selectors?('a.cls b#id') # => true
        #   multiple_selectors?('a.cls') # => false
        def multiple_selectors?(selector)
          normalize = selector.gsub(/(\\[>,+~]|\(.*\))/, '')
          normalize.match?(/[ >,+~]/)
        end
      end
    end
  end
end
