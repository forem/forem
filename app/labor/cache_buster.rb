class CacheBuster
  TIMEFRAMES = [
    [1.week.ago, "week"], [1.month.ago, "month"], [1.year.ago, "year"], [5.years.ago, "infinity"]
  ].freeze

  def bust(path)
    return unless Rails.env.production?

    HTTParty.post("https://api.fastly.com/purge/https://dev.to#{path}",
    headers: { "Fastly-Key" => ApplicationConfig["FASTLY_API_KEY"] })
    HTTParty.post("https://api.fastly.com/purge/https://dev.to#{path}?i=i",
    headers: { "Fastly-Key" => ApplicationConfig["FASTLY_API_KEY"] })
  end

  def bust_comment(commentable, username)
    if Article.where(published: true).order("hotness_score DESC").limit(3).pluck(:id).include?(commentable.id)
      bust("/")
    end
    if commentable.decorate.cached_tag_list_array.include?("discuss") &&
        commentable.featured_number.to_i > 35.hours.ago.to_i
      bust("/")
      bust("/?i=i")
      bust("?i=i")
    end
    bust("#{commentable.path}/comments/")
    bust(commentable.path.to_s)
    commentable.comments.each do |c|
      bust(c.path)
      bust(c.path + "?i=i")
    end
    bust("#{commentable.path}/comments/*")
    bust("/#{username}")
    bust("/#{username}/comments")
    bust("/#{username}/comments?i=i")
    bust("/#{username}/comments/?i=i")
  end

  def bust_article(article)
    bust("/" + article.user.username)
    bust(article.path + "/")
    bust(article.path + "?i=i")
    bust(article.path + "/?i=i")
    bust(article.path + "/comments")
    bust(article.path + "?preview=" + article.password)
    bust(article.path + "?preview=" + article.password + "&i=i")
    if article.organization.present?
      bust("/#{article.organization.slug}")
    end
    bust_home_pages(article)
    bust_tag_pages(article)
    bust("/api/articles/#{article.id}")
    bust("/api/articles/by_path?url=#{article.path}")

    article.collection&.articles&.each do |a|
      bust(a.path)
    end
  end

  def bust_home_pages(article)
    if article.featured_number.to_i > Time.current.to_i
      bust("/")
      bust("?i=i")
    end
    TIMEFRAMES.each do |timeframe|
      if Article.where(published: true).where("published_at > ?", timeframe[0]).
          order("positive_reactions_count DESC").limit(3).pluck(:id).include?(article.id)
        bust("/top/#{timeframe[1]}")
        bust("/top/#{timeframe[1]}?i=i")
        bust("/top/#{timeframe[1]}/?i=i")
      end
    end
    if article.published && article.published_at > 1.hour.ago
      bust("/latest")
      bust("/latest?i=i")
    end
    if Article.where(published: true).order("hotness_score DESC").limit(4).pluck(:id).include?(article.id)
      bust("/")
    end
  end

  def bust_tag_pages(article)
    return unless article.published

    article.tag_list.each do |tag|
      if article.published_at.to_i > 3.minutes.ago.to_i
        bust("/t/#{tag}/latest")
        bust("/t/#{tag}/latest?i=i")
      end
      TIMEFRAMES.each do |timeframe|
        if Article.where(published: true).where("published_at > ?", timeframe[0]).tagged_with(tag).
            order("positive_reactions_count DESC").limit(3).pluck(:id).include?(article.id)
          bust("/top/#{timeframe[1]}")
          bust("/top/#{timeframe[1]}?i=i")
          bust("/top/#{timeframe[1]}/?i=i")
          12.times do |i|
            bust("/api/articles?tag=#{tag}&top=#{i}")
          end
        end
        if Article.where(published: true).tagged_with(tag).
            order("hotness_score DESC").limit(2).pluck(:id).include?(article.id)
          bust("/t/#{tag}")
          bust("/t/#{tag}?i=i")
        end
      end
    end
  end
end
