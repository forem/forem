module EdgeCache
  class BustArticle < Bust
    def self.call(article)
      return unless article

      article.purge

      bust(article.path)
      bust("/#{article.user.username}")
      bust("#{article.path}/")
      bust("#{article.path}?i=i")
      bust("#{article.path}/?i=i")
      bust("#{article.path}/comments")
      bust("#{article.path}?preview=#{article.password}")
      bust("#{article.path}?preview=#{article.password}&i=i")
      bust("/#{article.organization.slug}") if article.organization.present?
      bust_home_pages(article)
      bust_tag_pages(article)
      bust("/api/articles/#{article.id}")

      return unless article.collection_id

      article.collection.articles.find_each do |collection_article|
        bust(collection_article.path)
      end
    end

    def self.bust_home_pages(article)
      if article.featured_number.to_i > Time.current.to_i
        bust("/")
        bust("?i=i")
      end

      if article.video.present? && article.featured_number.to_i > 10.days.ago.to_i
        bust("/videos")
        bust("/videos?i=i")
      end

      TIMEFRAMES.each do |timestamp, interval|
        next unless Article.published.where("published_at > ?", timestamp.call)
          .order(public_reactions_count: :desc).limit(3).ids.include?(article.id)

        bust("/top/#{interval}")
        bust("/top/#{interval}?i=i")
        bust("/top/#{interval}/?i=i")
      end

      if article.published && article.published_at > 1.hour.ago
        bust("/latest")
        bust("/latest?i=i")
      end

      bust("/") if Article.published.order(hotness_score: :desc).limit(4).ids.include?(article.id)
    end

    private_class_method :bust_home_pages

    def self.bust_tag_pages(article)
      return unless article.published

      article.tag_list.each do |tag|
        if article.published_at.to_i > 2.minutes.ago.to_i
          bust("/t/#{tag}/latest")
          bust("/t/#{tag}/latest?i=i")
        end

        TIMEFRAMES.each do |timestamp, interval|
          next unless Article.published.where("published_at > ?", timestamp.call).tagged_with(tag)
            .order(public_reactions_count: :desc).limit(3).ids.include?(article.id)

          bust("/top/#{interval}")
          bust("/top/#{interval}?i=i")
          bust("/top/#{interval}/?i=i")
          12.times do |i|
            bust("/api/articles?tag=#{tag}&top=#{i}")
          end
        end

        next unless rand(2) == 1 &&
          Article.published.tagged_with(tag)
            .order(hotness_score: :desc).limit(2).ids.include?(article.id)

        bust("/t/#{tag}")
        bust("/t/#{tag}?i=i")
      end
    end

    private_class_method :bust_tag_pages
  end
end
