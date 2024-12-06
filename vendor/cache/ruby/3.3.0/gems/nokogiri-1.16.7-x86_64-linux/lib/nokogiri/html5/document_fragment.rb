# coding: utf-8
# frozen_string_literal: true

#
#  Copyright 2013-2021 Sam Ruby, Stephen Checkoway
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

require_relative "../html4/document_fragment"

module Nokogiri
  module HTML5
    # Since v1.12.0
    #
    # 💡 HTML5 functionality is not available when running JRuby.
    class DocumentFragment < Nokogiri::HTML4::DocumentFragment
      attr_accessor :document
      attr_accessor :errors

      # Get the parser's quirks mode value. See HTML5::QuirksMode.
      #
      # This method returns `nil` if the parser was not invoked (e.g., `Nokogiri::HTML5::DocumentFragment.new(doc)`).
      #
      # Since v1.14.0
      attr_reader :quirks_mode

      # Create a document fragment.
      def initialize(doc, tags = nil, ctx = nil, options = {}) # rubocop:disable Lint/MissingSuper
        self.document = doc
        self.errors = []
        return self unless tags

        max_attributes = options[:max_attributes] || Nokogiri::Gumbo::DEFAULT_MAX_ATTRIBUTES
        max_errors = options[:max_errors] || Nokogiri::Gumbo::DEFAULT_MAX_ERRORS
        max_depth = options[:max_tree_depth] || Nokogiri::Gumbo::DEFAULT_MAX_TREE_DEPTH
        tags = Nokogiri::HTML5.read_and_encode(tags, nil)
        Nokogiri::Gumbo.fragment(self, tags, ctx, max_attributes, max_errors, max_depth)
      end

      def serialize(options = {}, &block) # :nodoc:
        # Bypass XML::Document.serialize which doesn't support options even
        # though XML::Node.serialize does!
        XML::Node.instance_method(:serialize).bind_call(self, options, &block)
      end

      # Parse a document fragment from +tags+, returning a Nodeset.
      def self.parse(tags, encoding = nil, options = {})
        doc = HTML5::Document.new
        tags = HTML5.read_and_encode(tags, encoding)
        doc.encoding = "UTF-8"
        new(doc, tags, nil, options)
      end

      def extract_params(params) # :nodoc:
        handler = params.find do |param|
          ![Hash, String, Symbol].include?(param.class)
        end
        params -= [handler] if handler

        hashes = []
        while Hash === params.last || params.last.nil?
          hashes << params.pop
          break if params.empty?
        end
        ns, binds = hashes.reverse

        ns ||=
          begin
            ns = {}
            children.each { |child| ns.merge!(child.namespaces) }
            ns
          end

        [params, handler, ns, binds]
      end
    end
  end
end
# vim: set shiftwidth=2 softtabstop=2 tabstop=8 expandtab:
