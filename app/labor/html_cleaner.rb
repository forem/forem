class HtmlCleaner

  def clean_html(html)
    doc = Nokogiri::HTML(html)
    # Remove Medium tracking pixel
    doc.css("img").each do |img|
      if img.attr('src') && (img.attr('src').include? "medium.com/_/stat")
        img.remove
      end
    end
    # Remove Medium catch phrase
    doc.css("p").each do |p|
      if p.text.include? "where people are continuing the conversation by highlighting"
        p.remove
      end
    end

    doc.css("pre br").each do |br|
      br.replace "\n"
    end
    doc.css('figure').each do |el|
      el.name = 'p'
    end

    doc.xpath('//@class').remove
    doc.to_html
  end


end
