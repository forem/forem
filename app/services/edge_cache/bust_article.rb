module EdgeCache
  class BustArticle
    TIMEFRAMES = [
      [-> { 1.week.ago }, "week"],
      [-> { 1.month.ago }, "month"],
      [-> { 1.year.ago }, "year"],
      [-> { 5.years.ago }, "infinity"],
    ].freeze

    def self.call(article)
      return unless article

      article.purge

      cache_bust = EdgeCache::Bust.new

      cache_bust.call(article.path)
      cache_bust.call("/#{article.user.username}")
      cache_bust.call("#{article.path}/")
      cache_bust.call("#{article.path}?i=i")
      cache_bust.call("#{article.path}/?i=i")
      cache_bust.call("#{article.path}/comments")
      cache_bust.call("#{article.path}?preview=#{article.password}")
      cache_bust.call("#{article.path}?preview=#{article.password}&i=i")
      cache_bust.call("/#{article.organization.slug}") if article.organization.present?
      bust_home_pages(cache_bust, article)
      bust_tag_pages(cache_bust, article)
      cache_bust.call("/api/articles/#{article.id}")

      return unless article.collection_id

      article.collection.articles.find_each do |collection_article|
        cache_bust.call(collection_article.path)
      end
    end

    def self.bust_home_pages(cache_bust, article)
      if article.featured_number.to_i > Time.current.to_i
        cache_bust.call("/")
        cache_bust.call("?i=i")
      end

      if article.video.present? && article.featured_number.to_i > 10.days.ago.to_i
        cache_bust.call("/videos")
        cache_bust.call("/videos?i=i")
      end

      TIMEFRAMES.each do |timestamp, interval|
        next unless Article.published.where("published_at > ?", timestamp.call)
          .order(public_reactions_count: :desc).limit(3).ids.include?(article.id)

        cache_bust.call("/top/#{interval}")
        cache_bust.call("/top/#{interval}?i=i")
        cache_bust.call("/top/#{interval}/?i=i")
      end

      if article.published && article.published_at > 1.hour.ago
        cache_bust.call("/latest")
        cache_bust.call("/latest?i=i")
      end

      cache_bust.call("/") if Article.published.order(hotness_score: :desc).limit(4).ids.include?(article.id)
    end

    private_class_method :bust_home_pages

    def self.bust_tag_pages(cache_bust, article)
      return unless article.published

      article.tag_list.each do |tag|
        if article.published_at.to_i > 2.minutes.ago.to_i
          cache_bust.call("/t/#{tag}/latest")
          cache_bust.call("/t/#{tag}/latest?i=i")
        end

        TIMEFRAMES.each do |timestamp, interval|
          next unless Article.published.where("published_at > ?", timestamp.call).tagged_with(tag)
            .order(public_reactions_count: :desc).limit(3).ids.include?(article.id)

          cache_bust.call("/top/#{interval}")
          cache_bust.call("/top/#{interval}?i=i")
          cache_bust.call("/top/#{interval}/?i=i")
          12.times do |i|
            cache_bust.call("/api/articles?tag=#{tag}&top=#{i}")
          end
        end

        next unless rand(2) == 1 &&
          Article.published.tagged_with(tag)
            .order(hotness_score: :desc).limit(2).ids.include?(article.id)

        cache_bust.call("/t/#{tag}")
        cache_bust.call("/t/#{tag}?i=i")
      end
    end

    private_class_method :bust_tag_pages
  end
end
