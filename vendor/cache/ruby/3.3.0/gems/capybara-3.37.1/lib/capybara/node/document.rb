# frozen_string_literal: true

module Capybara
  module Node
    ##
    #
    # A {Capybara::Document} represents an HTML document. Any operation
    # performed on it will be performed on the entire document.
    #
    # @see Capybara::Node
    #
    class Document < Base
      include Capybara::Node::DocumentMatchers

      def inspect
        %(#<Capybara::Document>)
      end

      ##
      #
      # @return [String]    The text of the document
      #
      def text(type = nil, normalize_ws: false)
        find(:xpath, '/html').text(type, normalize_ws: normalize_ws)
      end

      ##
      #
      # @return [String]    The title of the document
      #
      def title
        session.driver.title
      end

      def execute_script(*args)
        find(:xpath, '/html').execute_script(*args)
      end

      def evaluate_script(*args)
        find(:xpath, '/html').evaluate_script(*args)
      end

      def scroll_to(*args, quirks: false, **options)
        find(:xpath, quirks ? '//body' : '/html').scroll_to(*args, **options)
      end
    end
  end
end
