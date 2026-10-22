module Images
  # Picks the opening lines of an article to feature on its generated social image.
  #
  # Platforms already show the title next to the image, so the card leads with how
  # the post starts instead. Paragraphs that are entirely italic (e.g. challenge
  # "This is a submission for..." intros) or that repeat the title are skipped.
  # Short paragraphs are joined until the quote reaches MIN_LENGTH, then it is cut
  # at the last sentence boundary within MAX_LENGTH (or at a word, with an ellipsis).
  class SocialImageQuote
    MIN_LENGTH = 80
    MAX_LENGTH = 180
    MIN_SENTENCE_CUT = 60
    SENTENCE_END = /[.!?]["'\u201D\u2019)\]]*(?=\s|\z)/

    def self.call(article)
      from_html(article.processed_html, article.title)
    end

    def self.from_html(html, title)
      new(html, title).call
    end

    def initialize(html, title)
      @html = html
      @title = title
    end

    def call
      quote = opening_text
      quote = clean(title) if quote.blank?
      shorten(quote)
    end

    private

    attr_reader :html, :title

    def opening_text
      text = ""
      Nokogiri::HTML.fragment(html.to_s).xpath("./p").each do |paragraph|
        next if skippable?(paragraph)

        line = clean(paragraph.text)
        next if line.blank?

        text = [text, line].compact_blank.join(" ")
        break if text.length >= MIN_LENGTH
      end
      text
    end

    def skippable?(paragraph)
      content = paragraph.children.reject { |node| node.text? && node.text.strip.empty? }
      return true if content.one? && %w[em i].include?(content.first.name)

      clean(paragraph.text).casecmp?(clean(title))
    end

    # NFKC turns "fancy" Unicode letters (e.g. mathematical bold) into plain ones,
    # and emoji are dropped because the card's fonts have no glyphs for them.
    def clean(text)
      text.to_s.unicode_normalize(:nfkc).gsub(/[\p{Extended_Pictographic}\uFE0F\u200D]/, "").squish
    end

    def shorten(text)
      return text if text.length <= MAX_LENGTH

      window = text[0, MAX_LENGTH]
      last_end = nil
      window.scan(SENTENCE_END) { last_end = Regexp.last_match.end(0) }
      return window[0, last_end] if last_end && last_end >= MIN_SENTENCE_CUT

      text.truncate(MAX_LENGTH, separator: " ", omission: "\u2026")
    end
  end
end
