# frozen_string_literal: true

require "yaml"

class AsciidocToMarkdown
  BREAKS = { "'''" => "---", "***" => "---", "---" => "---" }.freeze
  ADMONITIONS = %w[NOTE TIP IMPORTANT WARNING CAUTION].freeze

  def self.call(asciidoc, **)
    new(asciidoc, **).call
  end

  def self.perform(asciidoc, **)
    call(asciidoc, **)
  end

  def initialize(asciidoc, front_matter: true)
    @raw = asciidoc.to_s
    @front_matter = front_matter
  end

  def call
    return "" if @raw.strip.empty?

    # 1. Protect Forem Liquid tags from regex mangling
    text, liquid_tags = mask_liquid_tags(@raw)

    # 2. Parse lines and transform into Markdown
    body, metadata = parse_document(text)

    # 3. Restore Liquid tags
    result = unmask_liquid_tags(body, liquid_tags)

    # 4. Wrap with YAML Front Matter if metadata was present
    if @front_matter && metadata.any?
      "#{YAML.dump(metadata).strip}\n---\n\n#{result.strip}\n"
    elsif !@front_matter && metadata["title"]
      "# #{metadata['title']}\n\n#{result.strip}\n"
    else
      "#{result.strip}\n"
    end
  end

  private

  # Mask {% embed ... %} and {{ var }} so markdown regexes leave them intact
  def mask_liquid_tags(text)
    tags = []
    masked = text.gsub(/(?:\{%.*?%\}|\{\{.*?\}\})/m) do |m|
      tags << m
      "<!--LIQUID_#{tags.size - 1}-->"
    end
    [masked, tags]
  end

  def unmask_liquid_tags(text, tags)
    tags.each_with_index.reduce(text) { |str, (tag, i)| str.gsub("<!--LIQUID_#{i}-->", tag) }
  end

  def parse_document(text)
    output = []
    metadata = {}
    doc_attrs = {}

    in_header = true
    in_code = false
    code_lang = ""
    in_quote = false
    quote_author = nil
    in_admonition = false
    in_table = false
    table_header_done = false

    text.each_line(chomp: true) do |line|
      # 1. Code Blocks (---- or ....)
      if line =~ /^(-{4,}|\.{4,})$/
        if in_code
          output << "```"
          in_code = false
          code_lang = ""
        else
          output << "```#{code_lang}".strip
          in_code = true
        end
        next
      end

      if in_code
        output << convert_conums(line)
        next
      end

      # 2. Tables (|===)
      if line =~ /^\|={3,}$/
        in_table = !in_table
        table_header_done = false
        next
      end

      if in_table
        table_row = render_table_row(line, table_header_done, doc_attrs)
        if table_row
          table_header_done = true
          output << table_row
        end
        next
      end

      # 3. Blockquotes (____) & Admonition Blocks (====)
      if line =~ /^_{4,}$/
        if in_quote
          if quote_author
            output << ">"
            output << "> — #{quote_author}"
            quote_author = nil
          end
          in_quote = false
        else
          in_quote = true
        end
        next
      end

      if in_quote
        output << (line.empty? ? ">" : "> #{render_inline(line, doc_attrs)}")
        next
      end

      if line =~ /^={4,}$/
        in_admonition = !in_admonition
        next
      end

      if in_admonition
        output << (line.empty? ? ">" : "> #{render_inline(line, doc_attrs)}")
        next
      end

      # 4. Document Header & Attributes (= Title, :key: val)
      if in_header
        if line =~ /^=\s+(.+)$/
          metadata["title"] = Regexp.last_match(1).strip
          doc_attrs["doctitle"] = metadata["title"]
          next
        elsif line =~ /^:([a-zA-Z0-9_-]+):\s*(.*)$/
          key = Regexp.last_match(1)
          val = Regexp.last_match(2).strip
          metadata[key] = val
          doc_attrs[key] = val
          next
        elsif line.strip.empty?
          in_header = false unless metadata.empty?
          output << "" unless metadata.any?
          next
        else
          in_header = false
        end
      end

      # 5. Block Metadata Options: [source,ruby], [quote, Author]
      if line =~ /^\[(.*)\]$/
        opts = Regexp.last_match(1).strip
        if opts =~ /^source(?:,\s*([a-zA-Z0-9_+-]+))?$/
          code_lang = Regexp.last_match(1) || ""
        elsif opts =~ /^quote(?:,\s*([^,]+))?(?:,\s*(.+))?$/
          quote_author = [Regexp.last_match(1), Regexp.last_match(2)].compact.map(&:strip).reject(&:empty?).join(", ")
        elsif ADMONITIONS.include?(opts)
          output << "> **#{opts.capitalize}:**"
        end
        next
      end

      # 6. Single-line Admonitions: NOTE: Remember to test.
      if line =~ /^(NOTE|TIP|IMPORTANT|WARNING|CAUTION):\s+(.+)$/
        label = Regexp.last_match(1).capitalize
        body = Regexp.last_match(2)
        output << "> **#{label}:** #{render_inline(body, doc_attrs)}"
        next
      end

      # 7. Thematic Breaks: ''', ***, ---
      if BREAKS.key?(line.strip)
        output << "---"
        next
      end

      # 8. Headings: == H2, === H3, etc.
      if line =~ /^(={2,6})\s+(.+)$/
        level = Regexp.last_match(1).length
        title = Regexp.last_match(2).strip
        output << "#{'#' * level} #{render_inline(title, doc_attrs)}"
        next
      end

      # 9. Lists (* or - or .)
      if line =~ /^\s*(\*+|-)\s+(.+)$/
        indent = "  " * (Regexp.last_match(1).length - 1)
        output << "#{indent}* #{render_inline(Regexp.last_match(2), doc_attrs)}"
        next
      elsif line =~ /^\s*(\.+)\s+(.+)$/
        indent = "  " * (Regexp.last_match(1).length - 1)
        output << "#{indent}1. #{render_inline(Regexp.last_match(2), doc_attrs)}"
        next
      end

      # 10. Block Images: image::url[alt]
      if line =~ /^image::([^\s\[]+)\[(.*?)\]$/
        output << "![#{Regexp.last_match(2)}](#{Regexp.last_match(1)})"
        next
      end

      # Standard paragraph line
      output << render_inline(line, doc_attrs)
    end

    [output.join("\n"), metadata]
  end

  def render_table_row(line, header_done, attrs)
    return nil if line.strip.empty?

    cells = line.split("|").map(&:strip).reject(&:empty?)
    return nil if cells.empty?

    formatted = cells.map { |c| render_inline(c, attrs) }
    row = "| #{formatted.join(' | ')} |"

    if header_done
      row
    else
      separator = "| #{Array.new(cells.size, '---').join(' | ')} |"
      "#{row}\n#{separator}"
    end
  end

  # Replace callout numbers <1>, <2> with circled unicode numbers ①, ②
  def convert_conums(line)
    return line unless line.include?("<")

    conums = {
      "<1>" => "①", "<2>" => "②", "<3>" => "③", "<4>" => "④", "<5>" => "⑤",
      "<6>" => "⑥", "<7>" => "⑦", "<8>" => "⑧", "<9>" => "⑨", "<10>" => "⑩"
    }
    conums.reduce(line) { |l, (k, v)| l.gsub(k, v) }
  end

  # Clean inline transformations: links, images, xrefs, formatting, and attributes
  def render_inline(text, attrs = {})
    res = text.dup

    # Substitute {attributes}
    res.gsub!(/\{([a-zA-Z0-9_-]+)\}/) { |m| attrs[Regexp.last_match(1)] || m } if res.include?("{")

    # Images: image:url[alt]
    res.gsub!(/image:([^\s\[]+)\[(.*?)\]/, '![\2](\1)') if res.include?("image:")

    # Cross-references: <<anchor,Label>> or <<anchor>>
    if res.include?("<<")
      res.gsub!(/<<([^\s,>]+)(?:,\s*([^>]+))?>>/) do
        m = Regexp.last_match
        anchor = m[1].sub(/^#?_?/, "")
        label = m[2] || anchor
        "[#{label}](##{anchor})"
      end
    end

    # Links: https://...[label] or link:...[label]
    if res.include?("://") || res.include?("link:")
      res.gsub!(%r{(?:link:)?(https?://[^\s\[]+)\[(.*?)\]}) do
        url = Regexp.last_match(1)
        label = Regexp.last_match(2).empty? ? url : Regexp.last_match(2)
        "[#{label}](#{url})"
      end
    end

    # Strikethrough: [.line-through]#text# -> ~~text~~
    res.gsub!(/\[\.?line-through\]#(\S|\S.*?\S)#/, '~~\1~~') if res.include?("line-through")

    # Mark: #highlight# -> <mark>highlight</mark>
    res.gsub!(/(?<![\w\\])#(\S|\S.*?\S)#(?![\w\\])/, '<mark>\1</mark>') if res.include?("#")

    # Drop meta in front of emphasis: [.role]*text*
    res.gsub!(/\[[^\[\]]+\](?=[*_])/, "") if res.include?("][") || res.include?("]*") || res.include?("]_")

    # Bold: *text* -> **text** (preserves escaped \* and within-word asterisks)
    res.gsub!(/(?<![\w\\])\*(\S|\S.*?\S)\*(?![\w\\])/, '**\1**') if res.include?("*")

    # Italic: _text_ -> *text* (when requested as standard markdown italics)
    res.gsub!(/(?<![\w\\])_(\S|\S.*?\S)_(?![\w\\])/, '*\1*') if res.include?("_")

    # Bold-Italic: ***text***
    res.gsub!(/\*\*_(.*?)_\*\*/, '***\1***') if res.include?("**_")

    res
  end
end
