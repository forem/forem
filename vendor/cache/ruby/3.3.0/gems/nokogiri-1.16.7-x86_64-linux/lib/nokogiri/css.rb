# coding: utf-8
# frozen_string_literal: true

module Nokogiri
  # Translate a CSS selector into an XPath 1.0 query
  module CSS
    class << self
      # TODO: Deprecate this method ahead of 2.0 and delete it in 2.0.
      # It is not used by Nokogiri and shouldn't be part of the public API.
      def parse(selector) # :nodoc:
        Parser.new.parse(selector)
      end

      # :call-seq:
      #   xpath_for(selector) → String
      #   xpath_for(selector [, prefix:] [, visitor:] [, ns:]) → String
      #
      # Translate a CSS selector to the equivalent XPath query.
      #
      # [Parameters]
      # - +selector+ (String) The CSS selector to be translated into XPath
      #
      # - +prefix:+ (String)
      #
      #   The XPath prefix for the query, see Nokogiri::XML::XPath for some options. Default is
      #   +XML::XPath::GLOBAL_SEARCH_PREFIX+.
      #
      # - +visitor:+ (Nokogiri::CSS::XPathVisitor)
      #
      #   The visitor class to use to transform the AST into XPath. Default is
      #   +Nokogiri::CSS::XPathVisitor.new+.
      #
      # - +ns:+ (Hash<String ⇒ String>)
      #
      #   The namespaces that are referenced in the query, if any. This is a hash where the keys are
      #   the namespace prefix and the values are the namespace URIs. Default is an empty Hash.
      #
      # [Returns] (String) The equivalent XPath query for +selector+
      #
      # 💡 Note that translated queries are cached for performance concerns.
      #
      def xpath_for(selector, options = {})
        raise TypeError, "no implicit conversion of #{selector.inspect} to String" unless selector.respond_to?(:to_str)

        selector = selector.to_str
        raise Nokogiri::CSS::SyntaxError, "empty CSS selector" if selector.empty?

        prefix = options.fetch(:prefix, Nokogiri::XML::XPath::GLOBAL_SEARCH_PREFIX)
        visitor = options.fetch(:visitor) { Nokogiri::CSS::XPathVisitor.new }
        ns = options.fetch(:ns, {})

        Parser.new(ns).xpath_for(selector, prefix, visitor)
      end
    end
  end
end

require_relative "css/node"
require_relative "css/xpath_visitor"
x = $-w
$-w = false
require_relative "css/parser"
$-w = x

require_relative "css/tokenizer"
require_relative "css/syntax_error"
