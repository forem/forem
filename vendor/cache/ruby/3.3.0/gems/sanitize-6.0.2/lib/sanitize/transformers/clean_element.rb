# encoding: utf-8

require 'cgi'
require 'set'

class Sanitize; module Transformers; class CleanElement

  # Matches a valid HTML5 data attribute name. The unicode ranges included here
  # are a conservative subset of the full range of characters that are
  # technically allowed, with the intent of matching the most common characters
  # used in data attribute names while excluding uncommon or potentially
  # misleading characters, or characters with the potential to be normalized
  # into unsafe or confusing forms.
  #
  # If you need data attr names with characters that aren't included here (such
  # as combining marks, full-width characters, or CJK), please consider creating
  # a custom transformer to validate attributes according to your needs.
  #
  # http://www.whatwg.org/specs/web-apps/current-work/multipage/elements.html#embedding-custom-non-visible-data-with-the-data-*-attributes
  REGEX_DATA_ATTR = /\Adata-(?!xml)[a-z_][\w.\u00E0-\u00F6\u00F8-\u017F\u01DD-\u02AF-]*\z/u

  # Elements whose content is treated as unescaped text by HTML parsers.
  UNESCAPED_TEXT_ELEMENTS = Set.new(%w[
    iframe
    noembed
    noframes
    noscript
    plaintext
    script
    style
    xmp
  ])

  # Attributes that need additional escaping on `<a>` elements due to unsafe
  # libxml2 behavior.
  UNSAFE_LIBXML_ATTRS_A = Set.new(%w[
    name
  ])

  # Attributes that need additional escaping on all elements due to unsafe
  # libxml2 behavior.
  UNSAFE_LIBXML_ATTRS_GLOBAL = Set.new(%w[
    action
    href
    src
  ])

  # Mapping of original characters to escape sequences for characters that
  # should be escaped in attributes affected by unsafe libxml2 behavior.
  UNSAFE_LIBXML_ESCAPE_CHARS = {
    ' ' => '%20',
    '"' => '%22'
  }

  # Regex that matches any single character that needs to be escaped in
  # attributes affected by unsafe libxml2 behavior.
  UNSAFE_LIBXML_ESCAPE_REGEX = /[ "]/

  def initialize(config)
    @add_attributes          = config[:add_attributes]
    @attributes              = config[:attributes].dup
    @elements                = config[:elements]
    @protocols               = config[:protocols]
    @remove_all_contents     = false
    @remove_element_contents = Set.new
    @whitespace_elements     = {}

    @attributes.each do |element_name, attrs|
      unless element_name == :all
        @attributes[element_name] = Set.new(attrs).merge(@attributes[:all] || [])
      end
    end

    # Backcompat: if :whitespace_elements is a Set, convert it to a hash.
    if config[:whitespace_elements].is_a?(Set)
      config[:whitespace_elements].each do |element|
        @whitespace_elements[element] = {:before => ' ', :after => ' '}
      end
    else
      @whitespace_elements = config[:whitespace_elements]
    end

    if config[:remove_contents].is_a?(Enumerable)
      @remove_element_contents.merge(config[:remove_contents].map(&:to_s))
    else
      @remove_all_contents = !!config[:remove_contents]
    end
  end

  def call(env)
    node = env[:node]
    return if node.type != Nokogiri::XML::Node::ELEMENT_NODE || env[:is_allowlisted]

    name = env[:node_name]

    # Delete any element that isn't in the config allowlist, unless the node has
    # already been deleted from the document.
    #
    # It's important that we not try to reparent the children of a node that has
    # already been deleted, since that seems to trigger a memory leak in
    # Nokogiri.
    unless @elements.include?(name) || node.parent.nil?
      # Elements like br, div, p, etc. need to be replaced with whitespace in
      # order to preserve readability.
      if @whitespace_elements.include?(name)
        node.add_previous_sibling(Nokogiri::XML::Text.new(@whitespace_elements[name][:before].to_s, node.document))

        unless node.children.empty?
          node.add_next_sibling(Nokogiri::XML::Text.new(@whitespace_elements[name][:after].to_s, node.document))
        end
      end

      unless node.children.empty?
        unless @remove_all_contents || @remove_element_contents.include?(name)
          node.add_previous_sibling(node.children)
        end
      end

      node.unlink
      return
    end

    attr_allowlist = @attributes[name] || @attributes[:all]

    if attr_allowlist.nil?
      # Delete all attributes from elements with no allowlisted attributes.
      node.attribute_nodes.each {|attr| attr.unlink }
    else
      allow_data_attributes = attr_allowlist.include?(:data)

      # Delete any attribute that isn't allowed on this element.
      node.attribute_nodes.each do |attr|
        attr_name = attr.name.downcase

        unless attr_allowlist.include?(attr_name)
          # The attribute isn't in the allowlist, but may still be allowed if
          # it's a data attribute.

          unless allow_data_attributes && attr_name.start_with?('data-') && attr_name =~ REGEX_DATA_ATTR
            # Either the attribute isn't a data attribute or arbitrary data
            # attributes aren't allowed. Remove the attribute.
            attr.unlink
            next
          end
        end

        # The attribute is allowed.

        # Remove any attributes that use unacceptable protocols.
        if @protocols.include?(name) && @protocols[name].include?(attr_name)
          attr_protocols = @protocols[name][attr_name]

          if attr.value =~ REGEX_PROTOCOL
            unless attr_protocols.include?($1.downcase)
              attr.unlink
              next
            end

          else
            unless attr_protocols.include?(:relative)
              attr.unlink
              next
            end
          end

          # Leading and trailing whitespace around URLs is ignored at parse
          # time. Stripping it here prevents it from being escaped by the
          # libxml2 workaround below.
          attr.value = attr.value.strip
        end

        # libxml2 >= 2.9.2 doesn't escape comments within some attributes, in an
        # attempt to preserve server-side includes. This can result in XSS since
        # an unescaped double quote can allow an attacker to inject a
        # non-allowlisted attribute.
        #
        # Sanitize works around this by implementing its own escaping for
        # affected attributes, some of which can exist on any element and some
        # of which can only exist on `<a>` elements.
        #
        # This fix is technically no longer necessary with Nokogumbo >= 2.0
        # since it no longer uses libxml2's serializer, but it's retained to
        # avoid breaking use cases where people might be sanitizing individual
        # Nokogiri nodes and then serializing them manually without Nokogumbo.
        #
        # The relevant libxml2 code is here:
        # <https://github.com/GNOME/libxml2/commit/960f0e275616cadc29671a218d7fb9b69eb35588>
        if UNSAFE_LIBXML_ATTRS_GLOBAL.include?(attr_name) ||
            (name == 'a' && UNSAFE_LIBXML_ATTRS_A.include?(attr_name))

          attr.value = attr.value.gsub(UNSAFE_LIBXML_ESCAPE_REGEX, UNSAFE_LIBXML_ESCAPE_CHARS)
        end
      end
    end

    # Add required attributes.
    if @add_attributes.include?(name)
      @add_attributes[name].each {|key, val| node[key] = val }
    end

    # Make a best effort to ensure that text nodes in invalid "unescaped text"
    # elements that are inside a math or svg namespace are properly escaped so
    # that they don't get parsed as HTML.
    #
    # Sanitize is explicitly documented as not supporting MathML or SVG, but
    # people sometimes allow `<math>` and `<svg>` elements in their custom
    # configs without realizing that it's not safe. This workaround makes it
    # slightly less unsafe, but you still shouldn't allow `<math>` or `<svg>`
    # because Nokogiri doesn't parse them the same way browsers do and Sanitize
    # can't guarantee that their contents are safe.
    unless node.namespace.nil?
      prefix = node.namespace.prefix

      if (prefix == 'math' || prefix == 'svg') && UNESCAPED_TEXT_ELEMENTS.include?(name)
        node.children.each do |child|
          if child.type == Nokogiri::XML::Node::TEXT_NODE
            child.content = CGI.escapeHTML(child.content)
          end
        end
      end
    end

    # Element-specific special cases.
    case name

    # If this is an allowlisted iframe that has children, remove all its
    # children. The HTML standard says iframes shouldn't have content, but when
    # they do, this content is parsed as text and is serialized verbatim without
    # being escaped, which is unsafe because legacy browsers may still render it
    # and execute `<script>` content. So the safe and correct thing to do is to
    # always remove iframe content.
    when 'iframe'
      if !node.children.empty?
        node.children.each do |child|
          child.unlink
        end
      end

    # Prevent the use of `<meta>` elements that set a charset other than UTF-8,
    # since Sanitize's output is always UTF-8.
    when 'meta'
      if node.has_attribute?('charset') &&
          node['charset'].downcase != 'utf-8'

        node['charset'] = 'utf-8'
      end

      if node.has_attribute?('http-equiv') &&
          node.has_attribute?('content') &&
          node['http-equiv'].downcase == 'content-type' &&
          node['content'].downcase =~ /;\s*charset\s*=\s*(?!utf-8)/

        node['content'] = node['content'].gsub(/;\s*charset\s*=.+\z/, ';charset=utf-8')
      end

    # A `<noscript>` element's content is parsed differently in browsers
    # depending on whether or not scripting is enabled. Since Nokogiri doesn't
    # support scripting, it always parses `<noscript>` elements as if scripting
    # is disabled. This results in edge cases where it's not possible to
    # reliably sanitize the contents of a `<noscript>` element because Nokogiri
    # can't fully replicate the parsing behavior of a scripting-enabled browser.
    # The safest thing to do is to simply remove all `<noscript>` elements.
    when 'noscript'
      node.unlink
    end
  end

end; end; end
