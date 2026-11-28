class BlackBox
  OUR_EPOCH_NUMBER = "2010-01-01 00:00:01".to_time.to_i # Arbitrary date, but the one we went with.
  class << self
    def article_hotness_score(article)
      return 0 unless article.published_at

      now = Time.current
      native_article_hotness_score(article, now) || legacy_article_hotness_score(article, now)
    end

    def comment_quality_score(comment)
      descendants_points = (comment.descendants.size / 2)
      rep_points = comment.reactions.sum(:points)
      bonus_points = calculate_bonus_score(comment.body_markdown)
      (rep_points + descendants_points + bonus_points).to_i
    end

    private

    # `ForemNative.article_hotness_score` assumes `4.days` / `7.days` are exact 96 / 168
    # hour spans, which only holds in a UTC zone (no DST transitions).
    def native_article_hotness_score(article, now)
      return unless now.utc?

      ForemNative.article_hotness_score(
        epoch_nanoseconds(article.published_at),
        article.crossposted_at && epoch_nanoseconds(article.crossposted_at),
        epoch_nanoseconds(now),
        OUR_EPOCH_NUMBER,
        article.score,
        article.comment_score,
        article.featured == true,
        article.respond_to?(:favorited?) && article.favorited?,
        article.cached_tag_list,
      )
    end

    def epoch_nanoseconds(time)
      (time.to_i * 1_000_000_000) + time.nsec
    end

    def legacy_article_hotness_score(article, now = Time.current)
      usable_date = article.crossposted_at || article.published_at
      reaction_points = article.score
      super_super_recent_bonus = usable_date > 1.hour.ago(now) ? 28 : 0
      super_recent_bonus = usable_date > 8.hours.ago(now) ? 81 : 0
      recency_bonus = usable_date > 12.hours.ago(now) ? 280 : 0
      today_bonus = usable_date > 26.hours.ago(now) ? 795 : 0
      two_day_bonus = usable_date > 48.hours.ago(now) ? 830 : 0
      four_day_bonus = usable_date > 96.hours.ago(now) ? 930 : 0
      curation_bonus = calculate_curation_bonus(article)
      if usable_date < 4.days.ago(now)
        reaction_points /= 2 # Older posts should fade
      end
      if usable_date < 7.days.ago(now)
        reaction_points /= 4 # Older posts should fade
      end
      if article.decorate.cached_tag_list_array.include?("watercooler")
        reaction_points = (reaction_points * 0.8).to_i # watercooler posts shouldn't get as much love in feed
      end

      article_hotness = last_mile_hotness_calc(article)

      (
        article_hotness + reaction_points + recency_bonus + super_recent_bonus +
        super_super_recent_bonus + today_bonus + two_day_bonus + four_day_bonus + curation_bonus
      )
    end

    def calculate_curation_bonus(article)
      featured_bonus = article.featured ? 200 : 0
      favorited_bonus = article.respond_to?(:favorited?) && article.favorited? ? 200 : 0
      featured_bonus + favorited_bonus
    end

    def calculate_bonus_score(body_markdown)
      size_bonus = body_markdown.size > 200 ? 2 : 0
      code_bonus = body_markdown.include?("`") ? 1 : 0
      size_bonus + code_bonus
    end

    def last_mile_hotness_calc(article)
      score_from_epoch = article.published_at.to_i - OUR_EPOCH_NUMBER # Approximate time of publish - epoch time
      (score_from_epoch / 1000) +
        ([article.score, 650].min * 2) +
        ([article.comment_score, 650].min * 2)
    end
  end
end
