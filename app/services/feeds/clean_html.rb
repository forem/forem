module Feeds
  class CleanHtml
    MEDIUM_TRACKING_PIXEL = "medium.com/_/stat".freeze
    MEDIUM_CATCHPHRASE = "where people are continuing the conversation by highlighting".freeze

    class << self
      def call(html)
        raw = html.to_s
        doc = Nokogiri::HTML(raw)
        clean_document!(doc, raw_html: raw).to_html
      end

      def clean_document!(doc, raw_html: nil)
        remove_tracking_pixels!(doc, raw_html)
        remove_catchphrases!(doc, raw_html)
        replace_figures_with_paragraphs!(doc, raw_html)
        remove_classes!(doc, raw_html)
        doc
      end

      private

      def remove_tracking_pixels!(doc, raw_html)
        return if raw_html&.exclude?(MEDIUM_TRACKING_PIXEL)

        doc.css("img").each do |img|
          img.remove if img.attr("src")&.include?(MEDIUM_TRACKING_PIXEL)
        end
      end

      def remove_catchphrases!(doc, raw_html)
        return if raw_html&.exclude?(MEDIUM_CATCHPHRASE)

        doc.css("p").each do |paragraph|
          paragraph.remove if paragraph.text.include?(MEDIUM_CATCHPHRASE)
        end
      end

      def replace_figures_with_paragraphs!(doc, raw_html)
        return if raw_html && !raw_html.match?(/<figure[\s>]/i)

        doc.css("figure").each do |el|
          el.name = "p"
        end
      end

      def remove_classes!(doc, raw_html)
        return if raw_html && !raw_html.match?(/\bclass\s*=/i)

        doc.xpath("//@class").remove
      end
    end
  end
end
