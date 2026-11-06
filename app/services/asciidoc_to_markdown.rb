# frozen_string_literal: true

require "yaml"

# Translates AsciiDoc text to GitHub Flavored Markdown for downstream Forem processing.
# Preserves Liquid tags, extracts document header attributes to YAML Front Matter,
# and converts block/inline AsciiDoc constructs into standard Markdown.
class AsciidocToMarkdown
  BREAKS = { "'''" => "---", "***" => "---", "---" => "---" }.freeze
  ADMONITIONS = %w[NOTE TIP IMPORTANT WARNING CAUTION].freeze
  CONUMS = {
    "<1>" => "①", "<2>" => "②", "<3>" => "③", "<4>" => "④", "<5>" => "⑤",
    "<6>" => "⑥", "<7>" => "⑦", "<8>" => "⑧", "<9>" => "⑨", "<10>" => "⑩"
  }.freeze

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
    @raw = asciidoc.to_s.delete("\u0000")
    @front_matter = front_matter
  end

  # Executes the conversion from AsciiDoc to Markdown.
  #
  # @return [String] converted Markdown string
  def call
    return "" if @raw.strip.empty?

    text, liquid_tags = mask_liquid_tags(@raw)
    body, metadata = parse_document(text)

    result = unmask_liquid_tags(body, liquid_tags)
    metadata = metadata.transform_values { |v| unmask_liquid_tags(v, liquid_tags) }

    format_output(result, metadata)
  end

  private

  # Wraps converted Markdown body with YAML Front Matter or ATX H1 title if applicable.
  #
  # @param result [String] converted Markdown body
  # @param metadata [Hash] extracted document attributes
  # @return [String] final formatted Markdown output
  def format_output(result, metadata)
    body_str = result.strip
    if @front_matter && metadata.any?
      fm = "#{YAML.dump(metadata).strip}\n---"
      body_str.empty? ? "#{fm}\n" : "#{fm}\n\n#{body_str}\n"
    elsif !@front_matter && metadata["title"]
      heading = "# #{metadata['title']}"
      body_str.empty? ? "#{heading}\n" : "#{heading}\n\n#{body_str}\n"
    else
      body_str.empty? ? "" : "#{body_str}\n"
    end
  end

  # Masks {% embed ... %} and {{ var }} so markdown regexes leave them intact.
  #
  # @param text [String] input text
  # @return [Array(String, Array<String>)] masked text and array of captured tags
  def mask_liquid_tags(text)
    tags = []
    masked = text.gsub(/(?:\{%.*?%\}|\{\{.*?\}\})/m) do |m|
      tags << m
      "LIQUID\u0000#{tags.size - 1}\u0000TAG"
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

    tags.each_with_index.reduce(text) { |str, (tag, i)| str.gsub("LIQUID\u0000#{i}\u0000TAG") { tag } }
  end

  # Parses document lines line-by-line and returns Markdown body and metadata.
  #
  # @param text [String] raw AsciiDoc body text
  # @return [Array(String, Hash)] markdown string and metadata hash
  def parse_document(text)
    state = initial_parse_state
    text.each_line(chomp: true) { |line| process_line(line, state) }
    flush_unclosed_blocks(state)
    [state[:output].join("\n"), state[:metadata]]
  end

  # Creates the initial parser state hash.
  #
  # @return [Hash] mutable state for document parsing
  def initial_parse_state
    {
      output: [],
      metadata: {},
      doc_attrs: {},
      in_header: true,
      comment_delimiter: nil,
      code_delimiter: nil,
      code_lang: "",
      code_lines: [],
      table_delimiter: nil,
      table_lines: [],
      table_header_option: nil,
      quote_delimiter: nil,
      quote_author: nil,
      admonition_delimiter: nil
    }
  end

  # Routes a single line through active block handlers, header extraction, or body conversion.
  #
  # @param line [String] current line
  # @param state [Hash] parser state
  # @return [void]
  def process_line(line, state)
    return if consume_comment?(line, state)
    return if consume_active_block?(line, state)
    return if state[:in_header] && consume_header_line?(line, state)
    return if consume_attribute_entry?(line, state)
    return if consume_block_opener?(line, state)
    return if consume_block_options?(line, state)

    reset_pending_options(state)
    handle_body_line(line, state)
  end

  # Defines or unsets a document attribute declared in the body, e.g. :name: value or :name!:.
  # Body attributes are available for {name} substitution but are not added to front matter.
  #
  # @param line [String] current line
  # @param state [Hash] parser state
  # @return [Boolean] true if the line was an attribute entry
  def consume_attribute_entry?(line, state)
    return false unless line =~ /^:([a-zA-Z0-9_-]+)(!)?:\s*(.*)$/

    if Regexp.last_match(2)
      state[:doc_attrs].delete(Regexp.last_match(1))
    else
      state[:doc_attrs][Regexp.last_match(1)] = Regexp.last_match(3).strip
    end
    true
  end

  # Processes single-line and block comments outside of code listings.
  #
  # @param line [String] current line
  # @param state [Hash] parser state
  # @return [Boolean] true if the line was consumed as a comment
  def consume_comment?(line, state)
    return false if state[:code_delimiter]

    if state[:comment_delimiter]
      state[:comment_delimiter] = nil if line == state[:comment_delimiter]
      return true
    end

    if line =~ %r{^/{4,}$}
      state[:comment_delimiter] = line
      return true
    end

    line.match?(%r{^//(?!/)})
  end

  # Processes lines inside an active code, table, quote, or admonition block.
  #
  # @param line [String] current line
  # @param state [Hash] parser state
  # @return [Boolean] true if the line was handled by an active block
  def consume_active_block?(line, state)
    if state[:code_delimiter]
      handle_code_line(line, state)
    elsif state[:table_delimiter]
      handle_table_line(line, state)
    elsif state[:quote_delimiter]
      handle_quote_line(line, state)
    elsif state[:admonition_delimiter]
      handle_admonition_line(line, state)
    else
      return false
    end
    true
  end

  # Appends a line to the open code listing or closes it on a matching delimiter.
  #
  # @param line [String] current line
  # @param state [Hash] parser state
  # @return [void]
  def handle_code_line(line, state)
    if line == state[:code_delimiter]
      emit_code_block(state)
    else
      state[:code_lines] << convert_conums(line)
    end
  end

  # Emits buffered code lines wrapped in a dynamic-length backtick fence.
  #
  # @param state [Hash] parser state
  # @return [void]
  def emit_code_block(state)
    max_ticks = state[:code_lines].flat_map { |l| l.scan(/`+/).map(&:length) }.max || 0
    fence = "`" * [3, max_ticks + 1].max
    state[:output] << "#{fence}#{state[:code_lang]}".strip
    state[:output].concat(state[:code_lines])
    state[:output] << fence
    state[:code_delimiter] = nil
    state[:code_lang] = ""
    state[:code_lines] = []
  end

  # Appends a line to the open table or renders it on a matching closing delimiter.
  #
  # @param line [String] current line
  # @param state [Hash] parser state
  # @return [void]
  def handle_table_line(line, state)
    if line == state[:table_delimiter]
      state[:output].concat(render_table(state[:table_lines], state[:table_header_option], state[:doc_attrs]))
      state[:table_delimiter] = nil
      state[:table_lines] = []
      state[:table_header_option] = nil
    else
      state[:table_lines] << line
    end
  end

  # Appends a line to the open blockquote or closes it with optional author attribution.
  #
  # @param line [String] current line
  # @param state [Hash] parser state
  # @return [void]
  def handle_quote_line(line, state)
    if line == state[:quote_delimiter]
      if state[:quote_author]
        state[:output] << ">"
        state[:output] << "> — #{state[:quote_author]}"
        state[:quote_author] = nil
      end
      state[:quote_delimiter] = nil
    else
      state[:output] << (line.empty? ? ">" : "> #{render_inline(line, state[:doc_attrs])}")
    end
  end

  # Appends a line to the open admonition block or closes it on a matching delimiter.
  #
  # @param line [String] current line
  # @param state [Hash] parser state
  # @return [void]
  def handle_admonition_line(line, state)
    if line == state[:admonition_delimiter]
      state[:admonition_delimiter] = nil
    else
      state[:output] << (line.empty? ? ">" : "> #{render_inline(line, state[:doc_attrs])}")
    end
  end

  # Extracts document title and attributes while in the document header.
  #
  # @param line [String] current line
  # @param state [Hash] parser state
  # @return [Boolean] true if the line was consumed as part of the header
  def consume_header_line?(line, state)
    if !state[:metadata].key?("title") && line =~ /^=\s+(.+)$/
      title = Regexp.last_match(1).strip
      state[:metadata]["title"] = title
      state[:doc_attrs]["doctitle"] = title
      true
    elsif line =~ /^:([a-zA-Z0-9_-]+):\s*(.*)$/
      key = Regexp.last_match(1)
      val = Regexp.last_match(2).strip
      state[:metadata][key] = val
      state[:doc_attrs][key] = val
      true
    elsif line.strip.empty?
      state[:in_header] = false unless state[:metadata].empty?
      state[:output] << "" unless state[:metadata].any?
      true
    else
      state[:in_header] = false
      false
    end
  end

  # Detects opening delimiters for code, table, quote, and admonition blocks.
  #
  # @param line [String] current line
  # @param state [Hash] parser state
  # @return [Boolean] true if a block was opened
  def consume_block_opener?(line, state)
    case line
    when /^(-{4,}|\.{4,})$/
      state[:code_delimiter] = line
      state[:code_lines] = []
      true
    when /^\|={3,}$/
      state[:table_delimiter] = line
      state[:table_lines] = []
      true
    when /^_{4,}$/
      state[:quote_delimiter] = line
      true
    when /^={4,}$/
      state[:admonition_delimiter] = line
      true
    else
      false
    end
  end

  # Parses bracketed block metadata options such as [source,ruby] or [options="header"].
  # Standalone block anchors like [[id]] are consumed and dropped.
  #
  # @param line [String] current line
  # @param state [Hash] parser state
  # @return [Boolean] true if the line was a block option list or block anchor
  def consume_block_options?(line, state)
    return true if line.match?(/^\[\[[^\[\]]+\]\]$/)
    return false unless line =~ /^\[([^\[\]]+)\]$/

    opts = Regexp.last_match(1).strip
    if opts =~ /^source(?:\s*,\s*([a-zA-Z0-9_+#.-]+))?(?:\s*,.*)?$/
      state[:code_lang] = Regexp.last_match(1) || ""
    elsif opts =~ /^quote(?:,\s*([^,]+))?(?:,\s*(.+))?$/
      parts = [Regexp.last_match(1), Regexp.last_match(2)].compact.map(&:strip).reject(&:empty?)
      state[:quote_author] = parts.join(", ")
    elsif opts =~ /(?:options|opts)=["']?[^"']*\bnoheader\b[^"']*["']?|(?<!\w)%noheader\b/
      state[:table_header_option] = :noheader
    elsif opts =~ /(?:options|opts)=["']?[^"']*\bheader\b[^"']*["']?|(?<!\w)%header\b/
      state[:table_header_option] = :header
    elsif ADMONITIONS.include?(opts)
      state[:output] << "> **#{opts.capitalize}:**"
    end
    true
  end

  # Clears any unconsumed block options when a non-delimited body line is reached.
  #
  # @param state [Hash] parser state
  # @return [void]
  def reset_pending_options(state)
    state[:code_lang] = ""
    state[:quote_author] = nil
    state[:table_header_option] = nil
  end

  # Converts standalone body lines (admonitions, breaks, headings, lists, images, paragraphs).
  #
  # @param line [String] current line
  # @param state [Hash] parser state
  # @return [void]
  def handle_body_line(line, state)
    attrs = state[:doc_attrs]
    output = state[:output]

    if line =~ /^(NOTE|TIP|IMPORTANT|WARNING|CAUTION):\s+(.+)$/
      output << "> **#{Regexp.last_match(1).capitalize}:** #{render_inline(Regexp.last_match(2), attrs)}"
    elsif BREAKS.key?(line.strip)
      output << "---"
    elsif line =~ /^(={2,6})\s+(.+)$/
      output << "#{'#' * Regexp.last_match(1).length} #{render_inline(Regexp.last_match(2).strip, attrs)}"
    elsif line =~ /^\s*(\*+|-)\s+(.+)$/
      indent = "  " * (Regexp.last_match(1).length - 1)
      output << "#{indent}* #{render_inline(Regexp.last_match(2), attrs)}"
    elsif line =~ /^\s*(\.+)\s+(.+)$/
      indent = "  " * (Regexp.last_match(1).length - 1)
      output << "#{indent}1. #{render_inline(Regexp.last_match(2), attrs)}"
    elsif line =~ /^image::([^\s\[]+)\[(.*?)\]$/
      url = substitute_attributes(Regexp.last_match(1), attrs)
      alt = substitute_attributes(Regexp.last_match(2), attrs)
      output << "![#{alt}](#{url})"
    else
      output << render_inline(line, attrs)
    end
  end

  # Emits any buffered content if input ends with an unclosed block.
  #
  # @param state [Hash] parser state
  # @return [void]
  def flush_unclosed_blocks(state)
    emit_code_block(state) if state[:code_delimiter]
    if state[:table_delimiter]
      table_rows = render_table(state[:table_lines], state[:table_header_option], state[:doc_attrs])
      state[:output].concat(table_rows)
    end
    return unless state[:quote_delimiter] && state[:quote_author]

    state[:output] << ">"
    state[:output] << "> — #{state[:quote_author]}"
  end

  # Formats table lines into GFM pipe table rows according to AsciiDoc header rules.
  #
  # @param lines [Array<String>] raw lines between table delimiters
  # @param header_option [Symbol, nil] :header, :noheader, or nil
  # @param attrs [Hash] document attributes for inline substitution
  # @return [Array<String>] formatted GFM table lines
  def render_table(lines, header_option, attrs)
    non_empty = lines.reject { |l| l.strip.empty? }
    return [] if non_empty.empty?

    first_cells = parse_table_cells(non_empty.first, attrs)
    ncols = first_cells.size
    return [] if ncols.zero?

    has_header = table_has_header?(lines, non_empty, header_option)
    body_lines = has_header ? non_empty.drop(1) : non_empty
    body_rows = body_lines.flat_map { |l| parse_table_cells(l, attrs) }.each_slice(ncols).to_a
    body_rows.last.fill("", body_rows.last.size...ncols) if body_rows.any?

    header = has_header ? first_cells : Array.new(ncols, "")
    [render_table_row(header), render_table_row(Array.new(ncols, "---"))] +
      body_rows.map { |r| render_table_row(r) }
  end

  # Determines whether the first row of a table should be promoted to a GFM header.
  #
  # @param lines [Array<String>] raw table lines including blank lines
  # @param non_empty [Array<String>] non-empty table row lines
  # @param header_option [Symbol, nil] explicit header option (:header or :noheader)
  # @return [Boolean] true if the table has a header row
  def table_has_header?(lines, non_empty, header_option)
    return true if header_option == :header
    return false if header_option == :noheader

    first_idx = lines.index { |l| !l.strip.empty? }
    return false unless first_idx && non_empty.size > 1

    lines[first_idx + 1].to_s.strip.empty?
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

    line.sub(/(?:\s*<(?:10|[1-9])>)+\s*\z/) do |tail|
      tail.gsub(/<(?:10|[1-9])>/) { |m| CONUMS[m] }
    end
  end

  # Substitutes {attribute} references using defined document attributes.
  #
  # @param text [String] input text
  # @param attrs [Hash] document attributes
  # @return [String] text with attributes substituted
  def substitute_attributes(text, attrs)
    return text unless text.include?("{")

    text.gsub(/\{([a-zA-Z0-9_-]+)\}/) { |m| attrs[Regexp.last_match(1)] || m }
  end

  # Performs inline transformations: links, images, xrefs, formatting, and attributes.
  #
  # @param text [String] inline text
  # @param attrs [Hash] document attributes
  # @return [String] formatted inline text
  def render_inline(text, attrs = {})
    res = substitute_attributes(text.dup, attrs)

    codes = []
    res.gsub!(/`[^`]+`/) { |m| "\x00CODE#{(codes << m).size - 1}\x00" } if res.include?("`")

    urls = []
    protect_url = ->(url) { "\x00URL#{(urls << url).size - 1}\x00" }

    apply_inline_macros(res, protect_url)
    apply_inline_formatting(res)

    urls.each_with_index { |u, i| res.gsub!("\x00URL#{i}\x00") { u } }
    codes.each_with_index { |c, i| res.gsub!("\x00CODE#{i}\x00") { c } }
    res
  end

  # Converts inline images, cross-references, and links while protecting target URLs.
  #
  # @param res [String] mutable string being transformed
  # @param protect_url [Proc] callable that masks a URL or alt text and returns a placeholder
  # @return [void]
  def apply_inline_macros(res, protect_url)
    if res.include?("image:")
      res.gsub!(/image:([^\s\[]+)\[(.*?)\]/) do
        "![#{protect_url.call(Regexp.last_match(2))}](#{protect_url.call(Regexp.last_match(1))})"
      end
    end

    if res.include?("<<")
      res.gsub!(/<<([^\s,>]+)(?:,\s*([^>]+))?>>/) do
        label = Regexp.last_match(2)
        anchor = Regexp.last_match(1).sub(/^#?_?/, "")
        "[#{label || anchor}](#{protect_url.call("##{anchor}")})"
      end
    end

    return unless res.include?("://") || res.include?("link:")

    res.gsub!(%r{(?:link:([^\s\[]+)|(https?://[^\s\[\]]+))\[(.*?)\]}) do
      url = Regexp.last_match(1) || Regexp.last_match(2)
      raw_label = Regexp.last_match(3)
      label = raw_label.empty? ? protect_url.call(url) : raw_label
      target = url.match?(/[()\s]/) ? "<#{url}>" : url
      "[#{label}](#{protect_url.call(target)})"
    end
  end

  # Applies strikethrough, mark, bold, and italic inline formatting.
  #
  # @param res [String] mutable string being transformed
  # @return [void]
  def apply_inline_formatting(res)
    res.gsub!(/\[\.?line-through\]#(?!\s)((?:[^\s#]|\s(?!#))*[^\s#])#/, '~~\1~~') if res.include?("line-through")
    res.gsub!(/(?<![\w\\])#(?!\d|\s)((?:[^\s#]|\s(?!#))*[^\s#])#(?![\w\\])/, '<mark>\1</mark>') if res.include?("#")
    res.gsub!(/\[[^\[\]]+\](?=[*_])/, "") if res.include?("][") || res.include?("]*") || res.include?("]_")
    res.gsub!(/(?<![\w\\*])\*(?!\s)((?:[^\s*]|\s(?!\*))*[^\s*])\*(?![\w*])/, '**\1**') if res.include?("*")
    res.gsub!(/(?<![\w\\_])_(?!\s)((?:[^\s_]|\s(?!_))*[^\s_])_(?![\w_])/, '*\1*') if res.include?("_")
  end
end
