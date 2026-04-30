class WebpageExtractor
  # Regular expression to find URLs in markdown, avoiding those in code blocks or liquid tags
  # This is a simplified regex; for production, we might want something more robust.
  URL_REGEX = %r{https?://[^\s<>"{}|\\^`\[\]]+}

  def self.extract(record)
    content = record.respond_to?(:body_markdown) ? record.body_markdown : nil
    return [] if content.blank?

    # Strip codeblocks and liquid tags to reliably extract active links only
    stripped_content = content.to_s
      .gsub(/```.*?```/m, "") # Fenced code blocks
      .gsub(/`.*?`/, "")     # Inline code
      .gsub(/\{%.*?%\}/, "") # Liquid tags

    urls = stripped_content.scan(URL_REGEX)
    
    # Clean up URLs (remove trailing punctuation often caught by regex, and markdown parentheses)
    urls.map! { |url| url.gsub(/[.,:;!?)]+$/, "") }
    
    urls.uniq
  end
end
