class BlackBox
  OUR_EPOCH_NUMBER = "2010-01-01 00:00:01".to_time.to_i # Arbitrary date, but the one we went with.
  class << self
    def article_hotness_score(article)
      usable_date = article.crossposted_at || article.published_at
      reaction_points = article.score
      super_super_recent_bonus = usable_date > 1.hour.ago ? 28 : 0
      super_recent_bonus = usable_date > 8.hours.ago ? 81 : 0
      recency_bonus = usable_date > 12.hours.ago ? 280 : 0
      today_bonus = usable_date > 26.hours.ago ? 795 : 0
      two_day_bonus = usable_date > 48.hours.ago ? 830 : 0
      four_day_bonus = usable_date > 96.hours.ago ? 930 : 0
      if usable_date < 4.days.ago
        reaction_points /= 2 # Older posts should fade
      end
      if article.decorate.cached_tag_list_array.include?("watercooler")
        reaction_points = (reaction_points * 0.8).to_i # watercooler posts shouldn't get as much love in feed
      end

      article_hotness = last_mile_hotness_calc(article)

      (
        article_hotness + reaction_points + recency_bonus + super_recent_bonus +
        super_super_recent_bonus + today_bonus + two_day_bonus + four_day_bonus
      )
    end

    def comment_quality_score(comment)
      descendants_points = (comment.descendants.size / 2)
      rep_points = comment.reactions.sum(:points)
      bonus_points = calculate_bonus_score(comment.body_markdown)
      spaminess_rating = calculate_spaminess(comment)
      (rep_points + descendants_points + bonus_points - spaminess_rating).to_i
    end

    def calculate_spaminess(story)
      user = story.user
      return 100 unless user
      return 0 if user.trusted
      return 0 if user.badge_achievements_count.positive?

      base_spaminess = 0
      base_spaminess += 25 if social_auth_registration_recent?(user) && user.registered_at > 25.days.ago
      base_spaminess
    end

    private

    def calculate_bonus_score(body_markdown)
      size_bonus = body_markdown.size > 200 ? 2 : 0
      code_bonus = body_markdown.include?("`") ? 1 : 0
      size_bonus + code_bonus
    end

    def last_mile_hotness_calc(article)
      score_from_epoch = article.featured_number.to_i - OUR_EPOCH_NUMBER # Approximate time of publish - epoch time
      score_from_epoch / 1000 +
        ([article.score, 650].min * 2) +
        ([article.comment_score, 650].min * 2) -
        (article.spaminess_rating * 5)
    end

    def social_auth_registration_recent?(user)
      # was the social auth account created very recently?
      social_auth_date_plus_two_days = ((user.github_created_at || user.twitter_created_at || 3.days.ago) + 2.days)
      user.registered_at < social_auth_date_plus_two_days
    end
  end
end
