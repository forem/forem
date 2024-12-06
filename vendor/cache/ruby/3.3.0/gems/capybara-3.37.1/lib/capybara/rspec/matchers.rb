# frozen_string_literal: true

require 'capybara/rspec/matchers/have_selector'
require 'capybara/rspec/matchers/have_ancestor'
require 'capybara/rspec/matchers/have_sibling'
require 'capybara/rspec/matchers/match_selector'
require 'capybara/rspec/matchers/have_current_path'
require 'capybara/rspec/matchers/match_style'
require 'capybara/rspec/matchers/have_text'
require 'capybara/rspec/matchers/have_title'
require 'capybara/rspec/matchers/become_closed'

module Capybara
  module RSpecMatchers
    # RSpec matcher for whether the element(s) matching a given selector exist.
    #
    # @see Capybara::Node::Matchers#assert_selector
    def have_selector(...)
      Matchers::HaveSelector.new(...)
    end

    # RSpec matcher for whether the element(s) matching a group of selectors exist.
    #
    # @see Capybara::Node::Matchers#assert_all_of_selectors
    def have_all_of_selectors(...)
      Matchers::HaveAllSelectors.new(...)
    end

    # RSpec matcher for whether no element(s) matching a group of selectors exist.
    #
    # @see Capybara::Node::Matchers#assert_none_of_selectors
    def have_none_of_selectors(...)
      Matchers::HaveNoSelectors.new(...)
    end

    # RSpec matcher for whether the element(s) matching any of a group of selectors exist.
    #
    # @see Capybara::Node::Matchers#assert_any_of_selectors
    def have_any_of_selectors(...)
      Matchers::HaveAnySelectors.new(...)
    end

    # RSpec matcher for whether the current element matches a given selector.
    #
    # @see Capybara::Node::Matchers#assert_matches_selector
    def match_selector(...)
      Matchers::MatchSelector.new(...)
    end

    %i[css xpath].each do |selector|
      define_method "have_#{selector}" do |expr, **options, &optional_filter_block|
        Matchers::HaveSelector.new(selector, expr, **options, &optional_filter_block)
      end

      define_method "match_#{selector}" do |expr, **options, &optional_filter_block|
        Matchers::MatchSelector.new(selector, expr, **options, &optional_filter_block)
      end
    end

    # @!method have_xpath(xpath, **options, &optional_filter_block)
    #   RSpec matcher for whether elements(s) matching a given xpath selector exist.
    #
    #   @see Capybara::Node::Matchers#has_xpath?

    # @!method have_css(css, **options, &optional_filter_block)
    #   RSpec matcher for whether elements(s) matching a given css selector exist
    #
    #   @see Capybara::Node::Matchers#has_css?

    # @!method match_xpath(xpath, **options, &optional_filter_block)
    #   RSpec matcher for whether the current element matches a given xpath selector.
    #
    #   @see Capybara::Node::Matchers#matches_xpath?

    # @!method match_css(css, **options, &optional_filter_block)
    #   RSpec matcher for whether the current element matches a given css selector.
    #
    #   @see Capybara::Node::Matchers#matches_css?

    %i[link button field select table].each do |selector|
      define_method "have_#{selector}" do |locator = nil, **options, &optional_filter_block|
        Matchers::HaveSelector.new(selector, locator, **options, &optional_filter_block)
      end
    end

    # @!method have_link(locator = nil, **options, &optional_filter_block)
    #   RSpec matcher for links.
    #
    #   @see Capybara::Node::Matchers#has_link?

    # @!method have_button(locator = nil, **options, &optional_filter_block)
    #   RSpec matcher for buttons.
    #
    #   @see Capybara::Node::Matchers#has_button?

    # @!method have_field(locator = nil, **options, &optional_filter_block)
    #   RSpec matcher for form fields.
    #
    #   @see Capybara::Node::Matchers#has_field?

    # @!method have_select(locator = nil, **options, &optional_filter_block)
    #   RSpec matcher for select elements.
    #
    #   @see Capybara::Node::Matchers#has_select?

    # @!method have_table(locator = nil, **options, &optional_filter_block)
    #   RSpec matcher for table elements.
    #
    #   @see Capybara::Node::Matchers#has_table?

    %i[checked unchecked].each do |state|
      define_method "have_#{state}_field" do |locator = nil, **options, &optional_filter_block|
        Matchers::HaveSelector.new(:field, locator, **options.merge(state => true), &optional_filter_block)
      end
    end

    # @!method have_checked_field(locator = nil, **options, &optional_filter_block)
    #   RSpec matcher for checked fields.
    #
    #   @see Capybara::Node::Matchers#has_checked_field?

    # @!method have_unchecked_field(locator = nil, **options, &optional_filter_block)
    #   RSpec matcher for unchecked fields.
    #
    #   @see Capybara::Node::Matchers#has_unchecked_field?

    # RSpec matcher for text content.
    #
    # @see Capybara::Node::Matchers#assert_text
    def have_text(text_or_type, *args, **options)
      Matchers::HaveText.new(text_or_type, *args, **options)
    end
    alias_method :have_content, :have_text

    def have_title(title, **options)
      Matchers::HaveTitle.new(title, **options)
    end

    # RSpec matcher for the current path.
    #
    # @see Capybara::SessionMatchers#assert_current_path
    def have_current_path(path, **options, &optional_filter_block)
      Matchers::HaveCurrentPath.new(path, **options, &optional_filter_block)
    end

    # RSpec matcher for element style.
    #
    # @see Capybara::Node::Matchers#matches_style?
    def match_style(styles = nil, **options)
      styles, options = options, {} if styles.nil?
      Matchers::MatchStyle.new(styles, **options)
    end

    ##
    # @deprecated
    #
    def have_style(styles = nil, **options)
      Capybara::Helpers.warn "DEPRECATED: have_style is deprecated, please use match_style : #{Capybara::Helpers.filter_backtrace(caller)}"
      match_style(styles, **options)
    end

    %w[selector css xpath text title current_path link button
       field checked_field unchecked_field select table
       sibling ancestor].each do |matcher_type|
      define_method "have_no_#{matcher_type}" do |*args, **kw_args, &optional_filter_block|
        Matchers::NegatedMatcher.new(send("have_#{matcher_type}", *args, **kw_args, &optional_filter_block))
      end
    end
    alias_method :have_no_content, :have_no_text

    %w[selector css xpath].each do |matcher_type|
      define_method "not_match_#{matcher_type}" do |*args, **kw_args, &optional_filter_block|
        Matchers::NegatedMatcher.new(send("match_#{matcher_type}", *args, **kw_args, &optional_filter_block))
      end
    end

    # RSpec matcher for whether sibling element(s) matching a given selector exist.
    #
    # @see Capybara::Node::Matchers#assert_sibling
    def have_sibling(...)
      Matchers::HaveSibling.new(...)
    end

    # RSpec matcher for whether ancestor element(s) matching a given selector exist.
    #
    # @see Capybara::Node::Matchers#assert_ancestor
    def have_ancestor(...)
      Matchers::HaveAncestor.new(...)
    end

    ##
    # Wait for window to become closed.
    #
    # @example
    #   expect(window).to become_closed(wait: 0.8)
    #
    # @option options [Numeric] :wait   Maximum wait time. Defaults to {Capybara.configure default_max_wait_time}
    def become_closed(**options)
      Matchers::BecomeClosed.new(options)
    end
  end
end
