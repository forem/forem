class FlareTag
  attr_accessor :article
  def initialize(article)
    @article = article.decorate
  end

  def tag
    Rails.cache.
      fetch("article_flare_tag-#{article.id}-#{article.updated_at}", expires_in: 12.hours) do
      flares = ["explainlikeimfive",
                "ama",
                "techtalks",
                "help",
                "news",
                "healthydebate",
                "showdev",
                "challenge",
                "anonymous",
                "hiring",
                "discuss"]
      flares.each do |f|
        return Tag.find_by_name(f) if article.cached_tag_list_array.include?(f)
      end
      nil
    end
  end

  def tag_hash
    return unless tag
    { name: tag.name,
      bg_color_hex: tag.bg_color_hex,
      text_color_hex: tag.text_color_hex }
  end
end
