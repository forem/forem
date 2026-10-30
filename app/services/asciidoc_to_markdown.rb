# frozen_string_literal: true

require "yaml"

# Translates AsciiDoc text to GitHub Flavored Markdown for downstream Forem processing.
# Preserves Liquid tags, extracts document header attributes to YAML Front Matter,
# and converts block/inline AsciiDoc constructs into standard Markdown.
class AsciidocToMarkdown
  BREAKS = { "'''" => "---", "***" => "---", "---" => "---" }.freeze
  ADMONITIONS = %w[NOTE TIP IMPORTANT WARNING CAUTION].freeze

  # Converts AsciiDoc input to Markdown.
  #
  # @param asciidoc [String, nil] raw AsciiDoc text
  # @param options [Hash] options forwarded to service instance
  # @return [String] generated Markdown with optional YAML Front Matter
  def self.call(asciidoc, **)
    new(asciidoc, **).call
  end

  # Alias for .call to adhere to Forem ApplicationService convention.
  #
  # @param asciidoc [String, nil] raw AsciiDoc text
  # @param options [Hash] options forwarded to service instance
  # @return [String] generated Markdown
  def self.perform(asciidoc, **)
    call(asciidoc, **)
  end

  # Initializes the AsciiDoc to Markdown converter.
  #
  # @param asciidoc [String, nil] raw AsciiDoc content
  # @param front_matter [Boolean] whether to extract document metadata as YAML Front Matter
  def initialize(asciidoc, front_matter: true)
    @raw = asciidoc.to_s
    @front_matter = front_matter
  end

  # Executes the conversion from AsciiDoc to Markdown.
  #
  # @return [String] converted Markdown string
  def call
    return "" if @raw.strip.empty?

    # 1. Protect Forem Liquid tags from regex mangling
    text, liquid_tags = mask_liquid_tags(@raw)

    # 2. Parse lines and transform into Markdown
    body, metadata = parse_document(text)

    # 3. Restore Liquid tags
    result = unmask_liquid_tags(body, liquid_tags)
    metadata = metadata.transform_values { |v| unmask_liquid_tags(v, liquid_tags) }

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

  # Masks {% embed ... %} and {{ var }} so markdown regexes leave them intact.
  #
  # @param text [String] input text
  # @return [Array(String, Array<String>)] masked text and array of captured tags
  def mask_liquid_tags(text)
    tags = []
    masked = text.gsub(/(?:\{%.*?%\}|\{\{.*?\}\})/m) do |m|
      tags << m
      "<!--LIQUID_#{tags.size - 1}-->"
    end
    [masked, tags]
  end

  # Restores previously masked Liquid tags.
  #
  # @param text [String, Object] masked markdown text or metadata value
  # @param tags [Array<String>] array of original Liquid tags
  # @return [String, Object] text with restored Liquid tags
  def unmask_liquid_tags(text, tags)
    return text unless text.is_a?(String)

    tags.each_with_index.reduce(text) { |str, (tag, i)| str.gsub("<!--LIQUID_#{i}-->", tag) }
  end

  # Parses document lines line-by-line and returns Markdown body and metadata.
  #
  # @param text [String] raw AsciiDoc body text
  # @return [Array(String, Hash)] markdown string and metadata hash
  def parse_document(text)
    output = []
    metadata = {}
    doc_attrs = {}

    in_header = true
    in_code = false
    code_delimiter = nil
    code_lang = ""
    code_lines = []
    comment_delimiter = nil
    in_quote = false
    quote_author = nil
    in_admonition = false
    in_table = false
    table_lines = []
    table_header_option = false

    text.each_line(chomp: true) do |line|
      # 0. Comments (// line and //// block), ignored inside code listings
      if comment_delimiter
        comment_delimiter = nil if line == comment_delimiter
        next
      end

      if !in_code && line =~ %r{^/{4,}$}
        comment_delimiter = line
        next
      end
      next if !in_code && line =~ %r{^//(?!/)}

      # 1. Code Blocks (---- or ....)
      if in_code
        if line == code_delimiter
          max_backticks = code_lines.flat_map { |l| l.scan(/`+/).map(&:length) }.max || 0
          fence = "`" * [3, max_backticks + 1].max
          output << "#{fence}#{code_lang}".strip
          output.concat(code_lines)
          output << fence
          in_code = false
          code_delimiter = nil
          code_lang = ""
          code_lines = []
        else
          code_lines << convert_conums(line)
        end
        next
      elsif line =~ /^(-{4,}|\.{4,})$/
        code_lines = []
        code_delimiter = line
        in_code = true
        next
      end

      # 2. Tables (|===)
      if line =~ /^\|={3,}$/
        if in_table
          output.concat(render_table(table_lines, table_header_option, doc_attrs))
          in_table = false
          table_lines = []
          table_header_option = false
        else
          in_table = true
          table_lines = []
        end
        next
      end

      if in_table
        table_lines << line
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
        if opts =~ /^source(?:\s*,\s*([a-zA-Z0-9_+#.-]+))?(?:\s*,.*)?$/
          code_lang = Regexp.last_match(1) || ""
        elsif opts =~ /^quote(?:,\s*([^,]+))?(?:,\s*(.+))?$/
          quote_author = [Regexp.last_match(1), Regexp.last_match(2)].compact.map(&:strip).reject(&:empty?).join(", ")
        elsif opts =~ /(?:options|opts)=["']?[^"']*header[^"']*["']?|%header/
          table_header_option = true
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

    if in_code
      max_backticks = code_lines.flat_map { |l| l.scan(/`+/).map(&:length) }.max || 0
      fence = "`" * [3, max_backticks + 1].max
      output << "#{fence}#{code_lang}".strip
      output.concat(code_lines)
      output << fence
    end

    if in_table
      output.concat(render_table(table_lines, table_header_option, doc_attrs))
    end

    [output.join("\n"), metadata]
  end

  # Formats table lines into GFM pipe table rows.
  #
  # @param lines [Array<String>] raw lines between table delimiters
  # @param has_header [Boolean] whether options="header" was specified
  # @param attrs [Hash] document attributes for inline substitution
  # @return [Array<String>] formatted GFM table lines
  def render_table(lines, has_header, attrs)
    non_empty = lines.reject { |l| l.strip.empty? }
    return [] if non_empty.empty?

    first_idx = lines.index { |l| !l.strip.empty? }
    followed_by_blank = first_idx && lines[first_idx + 1]&.strip&.empty?

    rows = []
    if has_header || followed_by_blank
      first_line = non_empty.shift
      header_cells = parse_table_cells(first_line, attrs)
      return [] if header_cells.empty?

      rows << render_table_row(header_cells)
      rows << render_table_row(Array.new(header_cells.size, '---'))
    else
      first_cells = parse_table_cells(non_empty.first, attrs)
      return [] if first_cells.empty?

      rows << render_table_row(Array.new(first_cells.size, ''))
      rows << render_table_row(Array.new(first_cells.size, '---'))
    end

    non_empty.each do |row_line|
      cells = parse_table_cells(row_line, attrs)
      rows << render_table_row(cells) unless cells.empty?
    end

    rows
  end

  # Formats a single table row with pipe delimiters.
  #
  # @param cells [Array<String>] row cell contents
  # @return [String] formatted GFM table row
  def render_table_row(cells)
    "| #{cells.join(' | ')} |"
  end

  # Splits a table row into formatted cells.
  #
  # @param line [String] raw table row line
  # @param attrs [Hash] document attributes for inline substitution
  # @return [Array<String>] array of formatted cell strings
  def parse_table_cells(line, attrs)
    cells = line.split(/(?<!\\)\|/, -1).map(&:strip)
    cells.shift if cells.first.to_s.empty?
    cells.map { |c| render_inline(c, attrs) }
  end

  # Replaces callout numbers <1>, <2> with circled unicode numbers ①, ②.
  #
  # @param line [String] line of code
  # @return [String] line with unicode callout numbers
  def convert_conums(line)
    return line unless line.include?("<")

    conums = {
      "<1>" => "①", "<2>" => "②", "<3>" => "③", "<4>" => "④", "<5>" => "⑤",
      "<6>" => "⑥", "<7>" => "⑦", "<8>" => "⑧", "<9>" => "⑨", "<10>" => "⑩"
    }
    conums.reduce(line) { |l, (k, v)| l.gsub(k, v) }
  end

  # Performs inline transformations: links, images, xrefs, formatting, and attributes.
  #
  # @param text [String] inline text
  # @param attrs [Hash] document attributes
  # @return [String] formatted inline text
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
