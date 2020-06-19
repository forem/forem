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
    @tag ||= if cached_tag_id
               Tag.select(%i[name bg_color_hex text_color_hex]).find_by(id: cached_tag_id)
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

  def cached_tag_id
    Rails.cache.fetch("article-#{article.id}_flare_tag_id-#{article.updated_at}", expires_in: 12.hours) do
      flare = FLARE_TAGS.detect { |tag| article.cached_tag_list_array.include?(tag) }
      if flare && flare != except_tag
        Tag.find_by(name: flare).id
      end
    end
  end
end
