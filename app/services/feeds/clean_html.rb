module Feeds
  class CleanHtml
    MEDIUM_TRACKING_PIXEL = "medium.com/_/stat".freeze
    MEDIUM_CATCHPHRASE = "where people are continuing the conversation by highlighting".freeze

    def self.call(html)
      doc = Nokogiri::HTML(html)
      # Remove Medium tracking pixel
      doc.css("img").each do |img|
        img.remove if img.attr("src")&.include?(MEDIUM_TRACKING_PIXEL)
      end
      # Remove Medium catch phrase
      doc.css("p").each do |paragraph|
        paragraph.remove if paragraph.text.include?(MEDIUM_CATCHPHRASE)
      end

      doc.css("figure").each do |el|
        el.name = "p"
      end

      doc.xpath("//@class").remove
      doc.to_html
    end
  end
end
