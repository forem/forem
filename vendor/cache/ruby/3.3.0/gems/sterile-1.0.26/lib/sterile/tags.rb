# encoding: UTF-8
require "nokogiri"


module Sterile

  class << self

    # Remove HTML/XML tags from text. Also strips out comments, PHP and ERB style tags.
    # CDATA is considered text unless :keep_cdata => false is specified.
    # Redundant whitespace will be removed unless :keep_whitespace => true is specified.
    #
    def strip_tags(string, options = {})
      options = {
        :keep_whitespace => false,
        :keep_cdata      => true
      }.merge!(options)

      string.gsub!(/<[%?](php)?[^>]*>/, '') # strip php, erb et al
      string.gsub!(/<!--[^-]*-->/, '')      # strip comments

      string.gsub!(
        /
          <!\[CDATA\[
          ([^\]]*)
          \]\]>
        /xi,
        options[:keep_cdata] ? '\\1' : ''
      )

      html_name = /[\w:-]+/
      html_data = /([A-Za-z0-9]+|('[^']*?'|"[^"]*?"))/
      html_attr = /(#{html_name}(\s*=\s*#{html_data})?)/

      string.gsub!(
        /
          <
          [\/]?
          #{html_name}
          (\s+(#{html_attr}(\s+#{html_attr})*))?
          \s*
          [\/]?
          >
        /xi,
        ''
      )

      options[:keep_whitespace] ? string : trim_whitespace(string)
    end


    # Similar to +gsub+, except it works in between HTML/XML tags and
    # yields text to a block. Text will be replaced by what the block
    # returns.
    # Warning: does not work in some degenerate cases.
    #
    def gsub_tags(string, &block)
      raise "No block given" unless block_given?

      fragment = Nokogiri::HTML::DocumentFragment.parse string
      fragment.traverse do |node|
        node.content = yield(node.content) if node.text?
      end
      fragment.to_html
    end


    # Iterates over all text in between HTML/XML tags and yields
    # it to a block.
    # Warning: does not work in some degenerate cases.
    #
    def scan_tags(string, &block)
      raise "No block given" unless block_given?

      fragment = Nokogiri::HTML::DocumentFragment.parse string
      fragment.traverse do |node|
        yield(node.content) if node.text?
      end
      nil
    end

  end # class << self

end # module Sterile

