module EdgeCache
  class BustArticle < Buster
    def self.call(article)
      return unless article

      article.purge

      buster = EdgeCache::Buster.new

      buster.bust(article.path)
      buster.bust("/#{article.user.username}")
      buster.bust("#{article.path}/")
      buster.bust("#{article.path}?i=i")
      buster.bust("#{article.path}/?i=i")
      buster.bust("#{article.path}/comments")
      buster.bust("#{article.path}?preview=#{article.password}")
      buster.bust("#{article.path}?preview=#{article.password}&i=i")
      buster.bust("/#{article.organization.slug}") if article.organization.present?
      bust_home_pages(buster, article)
      bust_tag_pages(buster, article)
      buster.bust("/api/articles/#{article.id}")

      return unless article.collection_id

      article.collection.articles.find_each do |collection_article|
        buster.bust(collection_article.path)
      end
    end

    def self.bust_home_pages(buster, article)
      if article.featured_number.to_i > Time.current.to_i
        buster.bust("/")
        buster.bust("?i=i")
      end

      if article.video.present? && article.featured_number.to_i > 10.days.ago.to_i
        buster.bust("/videos")
        buster.bust("/videos?i=i")
      end

      TIMEFRAMES.each do |timestamp, interval|
        next unless Article.published.where("published_at > ?", timestamp.call)
          .order(public_reactions_count: :desc).limit(3).ids.include?(article.id)

        buster.bust("/top/#{interval}")
        buster.bust("/top/#{interval}?i=i")
        buster.bust("/top/#{interval}/?i=i")
      end

      if article.published && article.published_at > 1.hour.ago
        buster.bust("/latest")
        buster.bust("/latest?i=i")
      end

      buster.bust("/") if Article.published.order(hotness_score: :desc).limit(4).ids.include?(article.id)
    end

    private_class_method :bust_home_pages

    def self.bust_tag_pages(buster, article)
      return unless article.published

      article.tag_list.each do |tag|
        if article.published_at.to_i > 2.minutes.ago.to_i
          buster.bust("/t/#{tag}/latest")
          buster.bust("/t/#{tag}/latest?i=i")
        end

        TIMEFRAMES.each do |timestamp, interval|
          next unless Article.published.where("published_at > ?", timestamp.call).tagged_with(tag)
            .order(public_reactions_count: :desc).limit(3).ids.include?(article.id)

          buster.bust("/top/#{interval}")
          buster.bust("/top/#{interval}?i=i")
          buster.bust("/top/#{interval}/?i=i")
          12.times do |i|
            buster.bust("/api/articles?tag=#{tag}&top=#{i}")
          end
        end

        next unless rand(2) == 1 &&
          Article.published.tagged_with(tag)
            .order(hotness_score: :desc).limit(2).ids.include?(article.id)

        buster.bust("/t/#{tag}")
        buster.bust("/t/#{tag}?i=i")
      end
    end

    private_class_method :bust_tag_pages
  end
end
