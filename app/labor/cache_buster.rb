module CacheBuster
  TIMEFRAMES = [
    [1.week.ago, "week"],
    [1.month.ago, "month"],
    [1.year.ago, "year"],
    [5.years.ago, "infinity"],
  ].freeze

  def self.bust(path)
    EdgeCache::Bust.call(path)
  end

  def self.bust_comment(commentable)
    return unless commentable

    bust_article_comment(commentable) if commentable.is_a?(Article)
    commentable.touch(:last_comment_at) if commentable.respond_to?(:last_comment_at)

    bust("#{commentable.path}/comments/")
    bust(commentable.path.to_s)
    commentable.comments.includes(:user).find_each do |comment|
      bust(comment.path)
      bust("#{comment.path}?i=i")
    end
    bust("#{commentable.path}/comments/*")
  end

  def self.bust_article(article)
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

    article.collection&.articles&.find_each do |collection_article|
      bust(collection_article.path)
    end
  end

  def self.bust_home_pages(article)
    if article.video.present? && article.featured_number.to_i > 10.days.ago.to_i
      bust("/videos")
      bust("/videos?i=i")
    end
    TIMEFRAMES.each do |timestamp, interval|
      next unless Article.published.where("published_at > ?", timestamp)
        .order(public_reactions_count: :desc).limit(3).ids.include?(article.id)

      bust("/top/#{interval}")
      bust("/top/#{interval}?i=i")
      bust("/top/#{interval}/?i=i")
    end
    if article.published && article.published_at > 1.hour.ago
      bust("/latest")
      bust("/latest?i=i")
    end

    return unless Article.published.order(hotness_score: :desc).limit(4).ids.include?(article.id)

    bust("/")
    EdgeCache::BustSidebar.call
  end

  def self.bust_tag_pages(article)
    return unless article.published

    article.tag_list.each do |tag|
      if article.published_at.to_i > 2.minutes.ago.to_i
        bust("/t/#{tag}/latest")
        bust("/t/#{tag}/latest?i=i")
      end
      TIMEFRAMES.each do |timestamp, interval|
        next unless Article.published.where("published_at > ?", timestamp).tagged_with(tag)
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

  def self.bust_page(slug)
    bust "/page/#{slug}"
    bust "/page/#{slug}?i=i"
    bust "/#{slug}"
    bust "/#{slug}?i=i"
  end

  def self.bust_tag(tag)
    tag.purge

    bust("/t/#{tag.name}")
    bust("/t/#{tag.name}?i=i")
    bust("/t/#{tag.name}/?i=i")
    bust("/t/#{tag.name}/")
    bust("/tags")
  end

  def self.bust_events
    bust("/events")
    bust("/events?i=i")
  end

  def self.bust_podcast(path)
    bust("/#{path}")
  end

  def self.bust_organization(organization, slug)
    bust("/#{slug}")
    begin
      organization.articles.find_each do |article|
        bust(article.path)
      end
    rescue StandardError => e
      Rails.logger.error("Tag issue: #{e}")
    end
  end

  def self.bust_podcast_episode(podcast_episode, path, podcast_slug)
    podcast_episode.purge
    podcast_episode.purge_all
    begin
      bust(path)
      bust("/#{podcast_slug}")
      bust("/pod")
      bust(path)
    rescue StandardError => e
      Rails.logger.warn(e)
    end
    podcast_episode.purge
    podcast_episode.purge_all
  end

  def self.bust_listings(listing)
    # we purge all listings as it's the wanted behavior with the following URL purging
    listing.purge_all

    bust("/listings")
    bust("/listings?i=i")
    bust("/listings/#{listing.category}/#{listing.slug}")
    bust("/listings/#{listing.category}/#{listing.slug}?i=i")
    bust("/listings/#{listing.category}")
  end

  def self.bust_user(user)
    username = user.username
    paths = [
      "/#{username}", "/#{username}?i=i",
      "/#{username}/comments",
      "/#{username}/comments?i=i", "/#{username}/comments/?i=i",
      "/live/#{username}", "/live/#{username}?i=i",
      "/feed/#{username}"
    ]
    paths.each { |path| bust(path) }
  end

  # bust commentable if it's an article
  def self.bust_article_comment(commentable)
    bust("/") if Article.published.order(hotness_score: :desc).limit(3).ids.include?(commentable.id)
    if commentable.decorate.cached_tag_list_array.include?("discuss") &&
        commentable.featured_number.to_i > 35.hours.ago.to_i
      bust("/")
      bust("/?i=i")
      bust("?i=i")
    end
  end
end
