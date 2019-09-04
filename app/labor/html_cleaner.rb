class HtmlCleaner
  def clean_html(html)
    doc = Nokogiri::HTML(html)
    # Remove Medium tracking pixel
    doc.css("img").each do |img|
      img.remove if img.attr("src") && (img.attr("src").include? "medium.com/_/stat")
    end
    # Remove Medium catch phrase
    doc.css("p").each do |paragraph|
      paragraph.remove if paragraph.text.include? "where people are continuing the conversation by highlighting"
    end

    doc.css("figure").each do |el|
      el.name = "p"
    end

    doc.xpath("//@class").remove
    doc.to_html
  end
end
