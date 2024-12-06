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

require_relative "html5/document"
require_relative "html5/document_fragment"
require_relative "html5/node"

module Nokogiri
  # Since v1.12.0
  #
  # ⚠ HTML5 functionality is not available when running JRuby.
  #
  # Parse an HTML5 document. Convenience method for {Nokogiri::HTML5::Document.parse}
  def self.HTML5(input, url = nil, encoding = nil, **options, &block)
    Nokogiri::HTML5::Document.parse(input, url, encoding, **options, &block)
  end

  # == Usage
  #
  # ⚠ HTML5 functionality is not available when running JRuby.
  #
  # Parse an HTML5 document:
  #
  #   doc = Nokogiri.HTML5(string)
  #
  # Parse an HTML5 fragment:
  #
  #   fragment = Nokogiri::HTML5.fragment(string)
  #
  # == Parsing options
  #
  # The document and fragment parsing methods support options that are different from Nokogiri's.
  #
  # - <tt>Nokogiri.HTML5(html, url = nil, encoding = nil, options = {})</tt>
  # - <tt>Nokogiri::HTML5.parse(html, url = nil, encoding = nil, options = {})</tt>
  # - <tt>Nokogiri::HTML5::Document.parse(html, url = nil, encoding = nil, options = {})</tt>
  # - <tt>Nokogiri::HTML5.fragment(html, encoding = nil, options = {})</tt>
  # - <tt>Nokogiri::HTML5::DocumentFragment.parse(html, encoding = nil, options = {})</tt>
  #
  # The three currently supported options are +:max_errors+, +:max_tree_depth+ and
  # +:max_attributes+, described below.
  #
  # === Error reporting
  #
  # Nokogiri contains an experimental HTML5 parse error reporting facility. By default, no parse
  # errors are reported but this can be configured by passing the +:max_errors+ option to
  # {HTML5.parse} or {HTML5.fragment}.
  #
  # For example, this script:
  #
  #   doc = Nokogiri::HTML5.parse('<span/>Hi there!</span foo=bar />', max_errors: 10)
  #   doc.errors.each do |err|
  #     puts(err)
  #   end
  #
  # Emits:
  #
  #   1:1: ERROR: Expected a doctype token
  #   <span/>Hi there!</span foo=bar />
  #   ^
  #   1:1: ERROR: Start tag of nonvoid HTML element ends with '/>', use '>'.
  #   <span/>Hi there!</span foo=bar />
  #   ^
  #   1:17: ERROR: End tag ends with '/>', use '>'.
  #   <span/>Hi there!</span foo=bar />
  #                   ^
  #   1:17: ERROR: End tag contains attributes.
  #   <span/>Hi there!</span foo=bar />
  #                   ^
  #
  # Using <tt>max_errors: -1</tt> results in an unlimited number of errors being returned.
  #
  # The errors returned by {HTML5::Document#errors} are instances of {Nokogiri::XML::SyntaxError}.
  #
  # The {https://html.spec.whatwg.org/multipage/parsing.html#parse-errors HTML standard} defines a
  # number of standard parse error codes. These error codes only cover the "tokenization" stage of
  # parsing HTML. The parse errors in the "tree construction" stage do not have standardized error
  # codes (yet).
  #
  # As a convenience to Nokogiri users, the defined error codes are available via
  # {Nokogiri::XML::SyntaxError#str1} method.
  #
  #   doc = Nokogiri::HTML5.parse('<span/>Hi there!</span foo=bar />', max_errors: 10)
  #   doc.errors.each do |err|
  #     puts("#{err.line}:#{err.column}: #{err.str1}")
  #   end
  #   # => 1:1: generic-parser
  #   #    1:1: non-void-html-element-start-tag-with-trailing-solidus
  #   #    1:17: end-tag-with-trailing-solidus
  #   #    1:17: end-tag-with-attributes
  #
  # Note that the first error is +generic-parser+ because it's an error from the tree construction
  # stage and doesn't have a standardized error code.
  #
  # For the purposes of semantic versioning, the error messages, error locations, and error codes
  # are not part of Nokogiri's public API. That is, these are subject to change without Nokogiri's
  # major version number changing. These may be stabilized in the future.
  #
  # === Maximum tree depth
  #
  # The maximum depth of the DOM tree parsed by the various parsing methods is configurable by the
  # +:max_tree_depth+ option. If the depth of the tree would exceed this limit, then an
  # {::ArgumentError} is thrown.
  #
  # This limit (which defaults to <tt>Nokogiri::Gumbo::DEFAULT_MAX_TREE_DEPTH = 400</tt>) can be
  # removed by giving the option <tt>max_tree_depth: -1</tt>.
  #
  #   html = '<!DOCTYPE html>' + '<div>' * 1000
  #   doc = Nokogiri.HTML5(html)
  #   # raises ArgumentError: Document tree depth limit exceeded
  #   doc = Nokogiri.HTML5(html, max_tree_depth: -1)
  #
  # === Attribute limit per element
  #
  # The maximum number of attributes per DOM element is configurable by the +:max_attributes+
  # option. If a given element would exceed this limit, then an {::ArgumentError} is thrown.
  #
  # This limit (which defaults to <tt>Nokogiri::Gumbo::DEFAULT_MAX_ATTRIBUTES = 400</tt>) can be
  # removed by giving the option <tt>max_attributes: -1</tt>.
  #
  #   html = '<!DOCTYPE html><div ' + (1..1000).map { |x| "attr-#{x}" }.join(' ') + '>'
  #   # "<!DOCTYPE html><div attr-1 attr-2 attr-3 ... attr-1000>"
  #   doc = Nokogiri.HTML5(html)
  #   # raises ArgumentError: Attributes per element limit exceeded
  #   doc = Nokogiri.HTML5(html, max_attributes: -1)
  #
  # == HTML Serialization
  #
  # After parsing HTML, it may be serialized using any of the {Nokogiri::XML::Node} serialization
  # methods. In particular, {XML::Node#serialize}, {XML::Node#to_html}, and {XML::Node#to_s} will
  # serialize a given node and its children. (This is the equivalent of JavaScript's
  # +Element.outerHTML+.) Similarly, {XML::Node#inner_html} will serialize the children of a given
  # node. (This is the equivalent of JavaScript's +Element.innerHTML+.)
  #
  #   doc = Nokogiri::HTML5("<!DOCTYPE html><span>Hello world!</span>")
  #   puts doc.serialize
  #   # => <!DOCTYPE html><html><head></head><body><span>Hello world!</span></body></html>
  #
  # Due to quirks in how HTML is parsed and serialized, it's possible for a DOM tree to be
  # serialized and then re-parsed, resulting in a different DOM.  Mostly, this happens with DOMs
  # produced from invalid HTML. Unfortunately, even valid HTML may not survive serialization and
  # re-parsing.
  #
  # In particular, a newline at the start of +pre+, +listing+, and +textarea+ elements is ignored by
  # the parser.
  #
  #   doc = Nokogiri::HTML5(<<-EOF)
  #   <!DOCTYPE html>
  #   <pre>
  #   Content</pre>
  #   EOF
  #   puts doc.at('/html/body/pre').serialize
  #   # => <pre>Content</pre>
  #
  # In this case, the original HTML is semantically equivalent to the serialized version. If the
  # +pre+, +listing+, or +textarea+ content starts with two newlines, the first newline will be
  # stripped on the first parse and the second newline will be stripped on the second, leading to
  # semantically different DOMs. Passing the parameter <tt>preserve_newline: true</tt> will cause
  # two or more newlines to be preserved. (A single leading newline will still be removed.)
  #
  #   doc = Nokogiri::HTML5(<<-EOF)
  #   <!DOCTYPE html>
  #   <listing>
  #
  #   Content</listing>
  #   EOF
  #   puts doc.at('/html/body/listing').serialize(preserve_newline: true)
  #   # => <listing>
  #   #
  #   #    Content</listing>
  #
  # == Encodings
  #
  # Nokogiri always parses HTML5 using {https://en.wikipedia.org/wiki/UTF-8 UTF-8}; however, the
  # encoding of the input can be explicitly selected via the optional +encoding+ parameter. This is
  # most useful when the input comes not from a string but from an IO object.
  #
  # When serializing a document or node, the encoding of the output string can be specified via the
  # +:encoding+ options. Characters that cannot be encoded in the selected encoding will be encoded
  # as {https://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references HTML numeric
  # entities}.
  #
  #   frag = Nokogiri::HTML5.fragment('<span>아는 길도 물어가라</span>')
  #   html = frag.serialize(encoding: 'US-ASCII')
  #   puts html
  #   # => <span>&#xc544;&#xb294; &#xae38;&#xb3c4; &#xbb3c;&#xc5b4;&#xac00;&#xb77c;</span>
  #   frag = Nokogiri::HTML5.fragment(html)
  #   puts frag.serialize
  #   # => <span>아는 길도 물어가라</span>
  #
  # (There's a {https://bugs.ruby-lang.org/issues/15033 bug} in all current versions of Ruby that
  # can cause the entity encoding to fail. Of the mandated supported encodings for HTML, the only
  # encoding I'm aware of that has this bug is <tt>'ISO-2022-JP'</tt>. We recommend avoiding this
  # encoding.)
  #
  # == Notes
  #
  # * The {Nokogiri::HTML5.fragment} function takes a string and parses it
  #   as a HTML5 document.  The +<html>+, +<head>+, and +<body>+ elements are
  #   removed from this document, and any children of these elements that remain
  #   are returned as a {Nokogiri::HTML5::DocumentFragment}.
  #
  # * The {Nokogiri::HTML5.parse} function takes a string and passes it to the
  #   <code>gumbo_parse_with_options</code> method, using the default options.
  #   The resulting Gumbo parse tree is then walked.
  #
  # * Instead of uppercase element names, lowercase element names are produced.
  #
  # * Instead of returning +unknown+ as the element name for unknown tags, the
  #   original tag name is returned verbatim.
  #
  # Since v1.12.0
  module HTML5
    class << self
      # Parse an HTML 5 document. Convenience method for {Nokogiri::HTML5::Document.parse}
      def parse(string, url = nil, encoding = nil, **options, &block)
        Document.parse(string, url, encoding, **options, &block)
      end

      # Parse a fragment from +string+. Convenience method for
      # {Nokogiri::HTML5::DocumentFragment.parse}.
      def fragment(string, encoding = nil, **options)
        DocumentFragment.parse(string, encoding, options)
      end

      # :nodoc:
      def read_and_encode(string, encoding)
        # Read the string with the given encoding.
        if string.respond_to?(:read)
          string = if encoding.nil?
            string.read
          else
            string.read(encoding: encoding)
          end
        else
          # Otherwise the string has the given encoding.
          string = string.to_s
          if encoding
            string = string.dup
            string.force_encoding(encoding)
          end
        end

        # convert to UTF-8
        if string.encoding != Encoding::UTF_8
          string = reencode(string)
        end
        string
      end

      private

      # Charset sniffing is a complex and controversial topic that understandably isn't done _by
      # default_ by the Ruby Net::HTTP library.  This being said, it is a very real problem for
      # consumers of HTML as the default for HTML is iso-8859-1, most "good" producers use utf-8, and
      # the Gumbo parser *only* supports utf-8.
      #
      # Accordingly, Nokogiri::HTML4::Document.parse provides limited encoding detection.  Following
      # this lead, Nokogiri::HTML5 attempts to do likewise, while attempting to more closely follow
      # the HTML5 standard.
      #
      # http://bugs.ruby-lang.org/issues/2567
      # http://www.w3.org/TR/html5/syntax.html#determining-the-character-encoding
      #
      def reencode(body, content_type = nil)
        if body.encoding == Encoding::ASCII_8BIT
          encoding = nil

          # look for a Byte Order Mark (BOM)
          initial_bytes = body[0..2].bytes
          if initial_bytes[0..2] == [0xEF, 0xBB, 0xBF]
            encoding = Encoding::UTF_8
          elsif initial_bytes[0..1] == [0xFE, 0xFF]
            encoding = Encoding::UTF_16BE
          elsif initial_bytes[0..1] == [0xFF, 0xFE]
            encoding = Encoding::UTF_16LE
          end

          # look for a charset in a content-encoding header
          if content_type
            encoding ||= content_type[/charset=["']?(.*?)($|["';\s])/i, 1]
          end

          # look for a charset in a meta tag in the first 1024 bytes
          unless encoding
            data = body[0..1023].gsub(/<!--.*?(-->|\Z)/m, "")
            data.scan(/<meta.*?>/im).each do |meta|
              encoding ||= meta[/charset=["']?([^>]*?)($|["'\s>])/im, 1]
            end
          end

          # if all else fails, default to the official default encoding for HTML
          encoding ||= Encoding::ISO_8859_1

          # change the encoding to match the detected or inferred encoding
          body = body.dup
          begin
            body.force_encoding(encoding)
          rescue ArgumentError
            body.force_encoding(Encoding::ISO_8859_1)
          end
        end

        body.encode(Encoding::UTF_8)
      end
    end
  end
end

require_relative "gumbo"
