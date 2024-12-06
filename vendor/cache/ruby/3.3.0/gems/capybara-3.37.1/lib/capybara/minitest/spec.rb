# frozen_string_literal: true

require 'minitest/spec'

module Capybara
  module Minitest
    module Expectations
      ##
      # Expectation that there is an ancestor
      #
      # @!method must_have_ancestor
      #   See {Capybara::Node::Matchers#has_ancestor?}

      ##
      # Expectation that there is button
      #
      # @!method must_have_button
      #   See {Capybara::Node::Matchers#has_button?}

      ##
      # Expectation that there is no button
      #
      # @!method wont_have_button
      #   See {Capybara::Node::Matchers#has_no_button?}

      ##
      # Expectation that there is checked_field
      #
      # @!method must_have_checked_field
      #   See {Capybara::Node::Matchers#has_checked_field?}

      ##
      # Expectation that there is no checked_field
      #
      # @!method wont_have_checked_field
      #   See {Capybara::Node::Matchers#has_no_checked_field?}

      ##
      # Expectation that there is unchecked_field
      #
      # @!method must_have_unchecked_field
      #   See {Capybara::Node::Matchers#has_unchecked_field?}

      ##
      # Expectation that there is no unchecked_field
      #
      # @!method wont_have_unchecked_field
      #   See {Capybara::Node::Matchers#has_no_unchecked_field?}

      ##
      # Expectation that page content does match
      #
      # @!method must_have_content
      #   See {Capybara::Node::Matchers#has_content?}

      ##
      # Expectation that page content does not match
      #
      # @!method wont_have_content
      #   See {Capybara::Node::Matchers#has_no_content?}

      ##
      # Expectation that there is css
      #
      # @!method must_have_css
      #   See {Capybara::Node::Matchers#has_css?}

      ##
      # Expectation that there is no css
      #
      # @!method wont_have_css
      #   See {Capybara::Node::Matchers#has_no_css?}

      ##
      # Expectation that current path matches
      #
      # @!method must_have_current_path
      #   See {Capybara::SessionMatchers#has_current_path?}

      ##
      # Expectation that current page does not match
      #
      # @!method wont_have_current_path
      #   See {Capybara::SessionMatchers#has_no_current_path?}

      ##
      # Expectation that there is field
      #
      # @!method must_have_field
      #   See {Capybara::Node::Matchers#has_field?}

      ##
      # Expectation that there is no field
      #
      # @!method wont_have_field
      #   See {Capybara::Node::Matchers#has_no_field?}

      ##
      # Expectation that there is link
      #
      # @!method must_have_link
      #   See {Capybara::Node::Matchers#has_link?}

      ##
      # Expectation that there is no link
      #
      # @!method wont_have_link
      #   See {Capybara::Node::Matchers#has_no_link?}

      ##
      # Expectation that page text does match
      #
      # @!method must_have_text
      #   See {Capybara::Node::Matchers#has_text?}

      ##
      # Expectation that page text does not match
      #
      # @!method wont_have_text
      #   See {Capybara::Node::Matchers#has_no_text?}

      ##
      # Expectation that page title does match
      #
      # @!method must_have_title
      #   See {Capybara::Node::DocumentMatchers#has_title?}

      ##
      # Expectation that page title does not match
      #
      # @!method wont_have_title
      #   See {Capybara::Node::DocumentMatchers#has_no_title?}

      ##
      # Expectation that there is select
      #
      # @!method must_have_select
      #   See {Capybara::Node::Matchers#has_select?}

      ##
      # Expectation that there is no select
      #
      # @!method wont_have_select
      #   See {Capybara::Node::Matchers#has_no_select?}

      ##
      # Expectation that there is a selector
      #
      # @!method must_have_selector
      #   See {Capybara::Node::Matchers#has_selector?}

      ##
      # Expectation that there is no selector
      #
      # @!method wont_have_selector
      #   See {Capybara::Node::Matchers#has_no_selector?}

      ##
      # Expectation that all of the provided selectors are present
      #
      # @!method must_have_all_of_selectors
      #   See {Capybara::Node::Matchers#assert_all_of_selectors}

      ##
      # Expectation that none of the provided selectors are present
      #
      # @!method must_have_none_of_selectors
      #   See {Capybara::Node::Matchers#assert_none_of_selectors}

      ##
      # Expectation that any of the provided selectors are present
      #
      # @!method must_have_any_of_selectors
      #   See {Capybara::Node::Matchers#assert_any_of_selectors}

      ##
      # Expectation that there is a sibling
      #
      # @!method must_have_sibling
      #   See {Capybara::Node::Matchers#has_sibling?}

      ##
      # Expectation that element has style
      #
      # @!method must_match_style
      #   See {Capybara::Node::Matchers#matches_style?}

      ##
      # Expectation that there is table
      #
      # @!method must_have_table
      #   See {Capybara::Node::Matchers#has_table?}

      ##
      # Expectation that there is no table
      #
      # @!method wont_have_table
      #   See {Capybara::Node::Matchers#has_no_table?}

      ##
      # Expectation that there is xpath
      #
      # @!method must_have_xpath
      #   See {Capybara::Node::Matchers#has_xpath?}

      ##
      # Expectation that there is no xpath
      #
      # @!method wont_have_xpath
      #   See {Capybara::Node::Matchers#has_no_xpath?}

      # This currently doesn't work for Ruby 2.8 due to Minitest not forwarding keyword args separately
      # %w[text content title current_path].each do |assertion|
      #   infect_an_assertion "assert_#{assertion}", "must_have_#{assertion}", :reverse
      #   infect_an_assertion "refute_#{assertion}", "wont_have_#{assertion}", :reverse
      # end

      # rubocop:disable Style/MultilineBlockChain
      (%w[text content title current_path
          selector xpath css link button field select table checked_field unchecked_field
          ancestor sibling].flat_map do |assertion|
            [%W[assert_#{assertion} must_have_#{assertion}],
             %W[refute_#{assertion} wont_have_#{assertion}]]
          end + [%w[assert_all_of_selectors must_have_all_of_selectors],
                 %w[assert_none_of_selectors must_have_none_of_selectors],
                 %w[assert_any_of_selectors must_have_any_of_selectors],
                 %w[assert_matches_style must_match_style]] +
      %w[selector xpath css].flat_map do |assertion|
        [%W[assert_matches_#{assertion} must_match_#{assertion}],
         %W[refute_matches_#{assertion} wont_match_#{assertion}]]
      end).each do |(meth, new_name)|
        class_eval <<-ASSERTION, __FILE__, __LINE__ + 1
          def #{new_name} *args, **kw_args, &block
            ::Minitest::Expectation.new(self, ::Minitest::Spec.current).#{new_name}(*args, **kw_args, &block)
          end
        ASSERTION

        ::Minitest::Expectation.class_eval <<-ASSERTION, __FILE__, __LINE__ + 1
          def #{new_name} *args, **kw_args, &block
            raise "Calling ##{new_name} outside of test." unless ctx
            ctx.#{meth}(target, *args, **kw_args, &block)
          end
        ASSERTION
      end
      # rubocop:enable Style/MultilineBlockChain

      ##
      # @deprecated
      def must_have_style(...)
        warn 'must_have_style is deprecated, please use must_match_style'
        must_match_style(...)
      end
    end
  end
end

class Capybara::Session
  include Capybara::Minitest::Expectations unless ENV['MT_NO_EXPECTATIONS']
end

class Capybara::Node::Base
  include Capybara::Minitest::Expectations unless ENV['MT_NO_EXPECTATIONS']
end

class Capybara::Node::Simple
  include Capybara::Minitest::Expectations unless ENV['MT_NO_EXPECTATIONS']
end
