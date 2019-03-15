class BlackBox
  class << self
    def article_hotness_score(article)
      return (article.featured_number || 10_000) / 10_000 unless Rails.env.production?

      usable_date = article.crossposted_at || article.published_at
      reaction_points = article.score
      super_super_recent_bonus = usable_date > 1.hours.ago ? 28 : 0
      super_recent_bonus = usable_date > 8.hours.ago ? 31 : 0
      recency_bonus = usable_date > 12.hours.ago ? 80 : 0
      today_bonus = usable_date > 26.hours.ago ? 395 : 0
      two_day_bonus = usable_date > 48.hours.ago ? 330 : 0
      four_day_bonus = usable_date > 96.hours.ago ? 330 : 0
      FunctionCaller.new("blackbox-production-articleHotness",
        { article: article, user: article.user }.to_json).call +
        reaction_points + recency_bonus + super_recent_bonus + super_super_recent_bonus + today_bonus + two_day_bonus + four_day_bonus
    end

    def comment_quality_score(comment)
      descendants_points = (comment.descendants.size / 2)
      rep_points = comment.reactions.sum(:points)
      bonus_points = calculate_bonus_score(comment.body_markdown)
      spaminess_rating = calculate_spaminess(comment)
      (rep_points + descendants_points + bonus_points - spaminess_rating).to_i
    end

    def calculate_spaminess(story)
      # accepts comment or article as story
      return 0 unless Rails.env.production?
      return 100 unless story.user

      FunctionCaller.new("blackbox-production-spamScore",
        { story: story, user: story.user }.to_json).call
    end

    private

    def calculate_bonus_score(body_markdown)
      size_bonus = body_markdown.size > 200 ? 2 : 0
      code_bonus = body_markdown.include?("`") ? 1 : 0
      size_bonus + code_bonus
    end
  end
end
