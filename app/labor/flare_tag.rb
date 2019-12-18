class FlareTag
  FLARE_TAGS = %w[explainlikeimfive
                  jokes
                  watercooler
                  ama
                  techtalks
                  todayilearned
                  help
                  news
                  healthydebate
                  showdev
                  challenge
                  anonymous
                  discuss].freeze

  def initialize(article, except_tag = nil)
    @article = article.decorate
    @except_tag = except_tag
  end

  def tag
    @tag ||= Rails.cache.fetch("article_flare_tag-#{article.id}-#{article.updated_at}", expires_in: 12.hours) do
      # Take the first flare tag to show up in the array
      flare = FLARE_TAGS.detect { |tag| article.cached_tag_list_array.include?(tag) }
      flare && flare != except_tag ? Tag.select(%i[name bg_color_hex text_color_hex]).find_by(name: flare) : nil
    end
  end

  def tag_hash
    return unless tag

    { name: tag.name,
      bg_color_hex: tag.bg_color_hex,
      text_color_hex: tag.text_color_hex }
  end

  private

  attr_reader :article, :except_tag
end
