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

      keys = [article.record_key]
      fallback_paths = [article.path].compact
      cutover_paths = []

      if article.id.present?
        bottom_items_path = "/bottom_items?article_id=#{article.id}"
        fallback_paths << bottom_items_path
        cutover_paths << bottom_items_path
      end

      if article.user
        keys.concat(article.user.profile_cache_keys)
        fallback_paths.concat(article.user.profile_cache_bust_paths)
        collect_legacy_redirect_paths(article, cutover_paths)
      end

      if article.organization
        keys << article.organization.record_key
        fallback_paths << article.organization.path if article.organization.respond_to?(:path)
      end

      collect_custom_domain_paths(article, fallback_paths)
      collect_home_page_targets(article, keys, fallback_paths)
      collect_tag_page_targets(article, keys, fallback_paths, cutover_paths)

      EdgeCache::PurgeByKey.call(keys.uniq, fallback_paths: fallback_paths.uniq)
      EdgeCache::CutoverUrlBust.call(cutover_paths)
    end

    def self.collect_legacy_redirect_paths(article, cutover_paths)
      return if article.slug.blank?

      user = article.user
      if article.organization && user.username.present?
        cutover_paths << "/#{user.username}/#{article.slug}"
      end
      cutover_paths << "/#{user.old_username}/#{article.slug}" if user.old_username.present?
      cutover_paths << "/#{user.old_old_username}/#{article.slug}" if user.old_old_username.present?
    end

    private_class_method :collect_legacy_redirect_paths

    def self.collect_custom_domain_paths(article, fallback_paths)
      org = article.organization
      return unless org.respond_to?(:custom_domain) &&
        org.custom_domain.present? &&
        FeatureFlag.enabled?(:org_custom_domain, FeatureFlag::Actor.new(org))

      fallback_paths << URL.url("/#{article.slug}", org.custom_domain)
    end

    private_class_method :collect_custom_domain_paths

    def self.collect_home_page_targets(article, keys, fallback_paths)
      if article.published_at.to_i > Time.current.to_i
        keys << "main_app_home_page"
        fallback_paths << "/"
      end

      if article.video.present? && article.published_at.to_i > 10.days.ago.to_i
        keys << "videos"
        fallback_paths << "/videos"
      end

      TIMEFRAMES.each do |timestamp, interval|
        cutoff = timestamp.call
        next if article.published_at.blank? || article.published_at <= cutoff
        break unless at_least_as_high_scoring(Article.published.where("published_at > ?", cutoff), article)
          .order(score: :desc).limit(3).ids.include?(article.id)

        keys << "stories-top-#{interval}"
        fallback_paths << "/top/#{interval}"
      end

      if article.published && article.published_at > 1.hour.ago
        keys << "stories-latest"
        fallback_paths << "/latest"
      end

      return unless at_least_as_hot(Article.published, article)
        .order(hotness_score: :desc).limit(4).ids.include?(article.id)

      keys << "main_app_home_page"
      fallback_paths << "/"
    end

    private_class_method :collect_home_page_targets

    def self.collect_tag_page_targets(article, keys, fallback_paths, cutover_paths)
      return unless article.published

      article.tag_list.each do |tag|
        tag_name = tag.to_s.downcase

        if article.published_at.to_i > 2.minutes.ago.to_i
          keys << "tag-#{tag_name}-latest"
          fallback_paths << "/t/#{tag_name}/latest"
          cutover_paths << "/t/#{tag_name}/latest"
        end

        collect_tag_timeframe_targets(article, tag_name, keys, fallback_paths, cutover_paths)

        next unless rand(2) == 1 &&
          at_least_as_hot(Article.published.cached_tagged_with(tag_name), article)
            .order(hotness_score: :desc).limit(2).ids.include?(article.id)

        keys << "tag-#{tag_name}-home"
        fallback_paths << "/t/#{tag_name}"
        cutover_paths << "/t/#{tag_name}"
      end
    end

    private_class_method :collect_tag_page_targets

    def self.collect_tag_timeframe_targets(article, tag_name, keys, fallback_paths, cutover_paths)
      TIMEFRAMES.each do |timestamp, interval|
        cutoff = timestamp.call
        next if article.published_at.blank? || article.published_at <= cutoff

        tagged_in_timeframe = Article.published.where("published_at > ?", cutoff).cached_tagged_with_any(tag_name)
        break unless at_least_as_high_scoring(tagged_in_timeframe, article)
          .order(score: :desc).limit(3).ids.include?(article.id)

        keys << "stories-top-#{interval}"
        keys << "tag-#{tag_name}-top-#{interval}"
        keys << "api-articles-tag-#{tag_name}-top"
        fallback_paths << "/top/#{interval}"
        fallback_paths << "/t/#{tag_name}/top/#{interval}"
        cutover_paths << "/t/#{tag_name}/top/#{interval}"
        12.times do |i|
          api_path = "/api/articles?tag=#{tag_name}&top=#{i}"
          fallback_paths << api_path
          cutover_paths << api_path
        end
      end
    end

    private_class_method :collect_tag_timeframe_targets

    # Only articles scoring at least as much as this one can rank ahead of it, so narrowing a top-3
    # check to them never changes whether it is in the top 3. The bound sits in the
    # index_articles_on_published_at_and_score index condition, so PostgreSQL stops fetching the heap
    # row (to check tags) of every lower-scoring article in the timeframe. The score is read from the
    # database, as the ranking is, rather than from a possibly stale in-memory article.
    def self.at_least_as_high_scoring(scope, article)
      scope.where("articles.score >= (SELECT ranked.score FROM articles AS ranked WHERE ranked.id = ?)", article.id)
    end

    private_class_method :at_least_as_high_scoring

    def self.at_least_as_hot(scope, article)
      scope.where(
        "articles.hotness_score >= (SELECT ranked.hotness_score FROM articles AS ranked WHERE ranked.id = ?)",
        article.id,
      )
    end

    private_class_method :at_least_as_hot
  end
end
