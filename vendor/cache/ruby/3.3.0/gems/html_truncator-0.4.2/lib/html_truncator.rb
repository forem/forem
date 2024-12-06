# encoding: utf-8

require "nokogiri"
require "set"
require "html_truncator/version"


class HTML_Truncator
  DEFAULT_OPTIONS = { :ellipsis => "…", :length_in_chars => false }

  def self.truncate(text, max, opts={})
    return truncate(text, max, :ellipsis => opts) if String === opts
    opts = DEFAULT_OPTIONS.merge(opts)
    doc = Nokogiri::HTML::DocumentFragment.parse(text)
    str, _, opts = doc.truncate(max, opts)
    eval "class <<str; def html_truncated?; #{opts[:was_truncated]} end end"
    str
  end

  class <<self
    attr_accessor :ellipsable_tags, :self_closing_tags, :punctuation_chars
  end
  self.ellipsable_tags = Set.new(%w(p ol ul li div header article nav section footer aside dd dt dl))
  self.self_closing_tags = Set.new(%w(br hr img param embed))
  self.punctuation_chars = %w(, . : ; ! ?)
end

class Nokogiri::HTML::DocumentFragment
  def ellipsable?
    true
  end
end

class Nokogiri::XML::Node
  def truncate(max, opts)
    return ["", 1, opts] if max == 0 && !ellipsable?
    inner, remaining, opts = inner_truncate(max, opts)
    if inner.empty?
      return [self_closing? ? to_html : "", max - remaining, opts]
    end
    children.remove
    add_child Nokogiri::HTML::DocumentFragment.parse(inner)
    [to_html(:indent => 0), max - remaining, opts]
  end

  def inner_truncate(max, opts)
    inner, remaining = "", max
    self.children.each do |node|
      txt, nb, opts = node.truncate(remaining, opts)
      remaining -= nb
      inner += txt
      next if remaining >= 0
      if ellipsable?
        r = %r/[\s#{HTML_Truncator.punctuation_chars.join}]+$/
        inner = inner.sub(r, '') + opts[:ellipsis]
        opts[:ellipsis] = ""
        opts[:was_truncated] = true
      end
      break
    end
    [inner, remaining, opts]
  end

  def ellipsable?
    HTML_Truncator.ellipsable_tags.include? name
  end

  def self_closing?
    HTML_Truncator.self_closing_tags.include? name
  end
end

class Nokogiri::XML::Text
  def truncate(max, opts)
    if opts[:length_in_chars]
      count = content.length
      return [to_xhtml, count, opts] if count <= max && max > 0
      words = content.scan(/[[:space:]]*[[:graph:]]+/)
      if words.size > 1
        words.inject('') do |string, word|
          if string.length + word.length > max
            txt = dup
            txt.content = string
            return [txt.to_xhtml, count, opts]
          end
          string + word
        end
      end
      txt = dup
      txt.content = content.slice(0, max)
      [txt.to_xhtml, count, opts]
    else
      words = to_xhtml.scan(/[[:space:]]*[[:graph:]]+/)
      count = words.length
      return [to_xhtml, count, opts] if count <= max && max > 0
      [words.slice(0, max).join, count, opts]
    end
  end
end
