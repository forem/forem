module Html
  class RemoveNestedLinebreakInList
    def self.call(html)
      return unless html

      html_doc = Nokogiri::HTML(html)
      html_doc.xpath("//*[self::ul or self::ol or self::li]/br").each(&:remove)
      html_doc.to_html
    end
  end
end
