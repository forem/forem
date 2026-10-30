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
      article.user&.purge
      article.organization&.purge

      cache_bust = EdgeCache::Bust.new

      bust_custom_domain_page(cache_bust, article)
      bust_home_pages(cache_bust, article)
      bust_tag_pages(cache_bust, article)
      bust_user_profile_pages(article)
    end

    def self.bust_custom_domain_page(cache_bust, article)
      org = article.organization
      return unless org.respond_to?(:custom_domain) &&
        org.custom_domain.present? &&
        FeatureFlag.enabled?(:org_custom_domain, FeatureFlag::Actor.new(org))

      custom_domain_url = URL.url("/#{article.slug}", org.custom_domain)
      cache_bust.call(custom_domain_url)
    end

    private_class_method :bust_custom_domain_page

    def self.bust_home_pages(cache_bust, article)
      if article.published_at.to_i > Time.current.to_i
        # TODO
        cache_bust.call("/")
      end

      if article.video.present? && article.published_at.to_i > 10.days.ago.to_i
        cache_bust.call("/videos")
      end

      TIMEFRAMES.each do |timestamp, interval|
        cutoff = timestamp.call
        next if article.published_at.blank? || article.published_at <= cutoff
        break unless at_least_as_high_scoring(Article.published.where("published_at > ?", cutoff), article)
          .order(score: :desc).limit(3).ids.include?(article.id)

        cache_bust.call("/top/#{interval}")
      end

      if article.published && article.published_at > 1.hour.ago
        cache_bust.call("/latest")
      end

      cache_bust.call("/") if Article.published.order(hotness_score: :desc).limit(4).ids.include?(article.id)
    end

    private_class_method :bust_home_pages

    def self.bust_tag_pages(cache_bust, article)
      return unless article.published

      # "/top/<interval>" repeats for every tag and "/api/articles?tag=<tag>&top=<i>" repeats for every
      # matching timeframe, so purge each path only once (each purge is two Fastly HTTP calls).
      busted_paths = Set.new
      bust_once = ->(path) { cache_bust.call(path) if busted_paths.add?(path) }

      article.tag_list.each do |tag|
        if article.published_at.to_i > 2.minutes.ago.to_i
          bust_once.call("/t/#{tag}/latest")
        end

        TIMEFRAMES.each do |timestamp, interval|
          cutoff = timestamp.call
          next if article.published_at.blank? || article.published_at <= cutoff

          tagged_in_timeframe = Article.published.where("published_at > ?", cutoff).cached_tagged_with_any(tag)
          break unless at_least_as_high_scoring(tagged_in_timeframe, article)
            .order(score: :desc).limit(3).ids.include?(article.id)

          bust_once.call("/top/#{interval}")
          12.times do |i|
            bust_once.call("/api/articles?tag=#{tag}&top=#{i}")
          end
        end

        next unless rand(2) == 1 &&
          Article.published.cached_tagged_with(tag)
            .order(hotness_score: :desc).limit(2).ids.include?(article.id)

        bust_once.call("/t/#{tag}")
      end
    end

    private_class_method :bust_tag_pages

    # Only articles scoring at least as much as this one can rank ahead of it, so narrowing a top-3
    # check to them never changes whether it is in the top 3. The bound sits in the
    # index_articles_on_published_at_and_score index condition, so PostgreSQL stops fetching the heap
    # row (to check tags) of every lower-scoring article in the timeframe. The score is read from the
    # database, as the ranking is, rather than from a possibly stale in-memory article.
    def self.at_least_as_high_scoring(scope, article)
      scope.where("articles.score >= (SELECT ranked.score FROM articles AS ranked WHERE ranked.id = ?)", article.id)
    end

    private_class_method :at_least_as_high_scoring

    def self.bust_user_profile_pages(article)
      return unless article.user

      EdgeCache::PurgeByKey.call(
        article.user.profile_cache_keys,
        fallback_paths: article.user.profile_cache_bust_paths,
      )
    end

    private_class_method :bust_user_profile_pages
  end
end
