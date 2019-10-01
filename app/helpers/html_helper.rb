module HtmlHelper
  def do_prefix_all_images(html, width)
    # wrap with Cloudinary or allow if from giphy or githubusercontent.com
    doc = Nokogiri::HTML.fragment(html)
    doc.css("img").each do |img|
      src = img.attr("src")
      next unless src
      next if allowed_image_host?(src)

      img["src"] = if giphy_img?(src)
                     src.gsub("https://media.", "https://i.")
                   else
                     img_of_size(src, width)
                   end
    end
    doc.to_html
  end

  def giphy_img?(source)
    uri = URI.parse(source)
    return false if uri.scheme != "https"
    return false if uri.userinfo || uri.fragment || uri.query
    return false if uri.host != "media.giphy.com" && uri.host != "i.giphy.com"
    return false if uri.port != 443 # I think it has to be this if its https?

    uri.path.ends_with?(".gif")
  end

  def allowed_image_host?(src)
    src.start_with?("https://res.cloudinary.com/")
  end
end
