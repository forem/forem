module Html
  class PrefixAllImages
    def self.call(html, width = 880)
      return unless html

      # wrap with Cloudinary or allow if from giphy or githubusercontent.com
      doc = Nokogiri::HTML.fragment(html)

      doc.css("img").each do |img|
        src = img.attr("src")
        next unless src

        # allow image to render as-is
        next if allowed_image_host?(src)

        img["loading"] = "lazy"
        img["src"] = if Giphy::Image.valid_url?(src)
                       src.gsub("https://media.", "https://i.")
                     else
                       img_of_size(src, width)
                     end
      end

      doc.to_html
    end

    def self.allowed_image_host?(src)
      # GitHub camo image won't parse but should be safe to host direct
      src.start_with?("https://camo.githubusercontent.com")
    end

    def self.img_of_size(source, width = 880)
      Images::Optimizer.call(source, width: width).gsub(",", "%2C")
    end
  end
end
