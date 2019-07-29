class BlackBox
  class << self
    def article_hotness_score(article, function_caller = FunctionCaller)
      usable_date = article.crossposted_at || article.published_at
      reaction_points = article.score
      super_super_recent_bonus = usable_date > 1.hour.ago ? 28 : 0
      super_recent_bonus = usable_date > 8.hours.ago ? 81 : 0
      recency_bonus = usable_date > 12.hours.ago ? 280 : 0
      today_bonus = usable_date > 26.hours.ago ? 495 : 0
      two_day_bonus = usable_date > 48.hours.ago ? 430 : 0
      four_day_bonus = usable_date > 96.hours.ago ? 430 : 0
      if usable_date < 10.days.ago
        reaction_points /= 2 # Older posts should fade
      end
      if article.decorate.cached_tag_list_array.include?("watercooler")
        reaction_points = (reaction_points * 0.8).to_i # watercooler posts shouldn't get as much love in feed
      end
      function_caller.call("blackbox-production-articleHotness",
                           { article: article, user: article.user }.to_json).to_i +
        reaction_points + recency_bonus + super_recent_bonus + super_super_recent_bonus + today_bonus + two_day_bonus + four_day_bonus
    end

    def comment_quality_score(comment)
      descendants_points = (comment.descendants.size / 2)
      rep_points = comment.reactions.sum(:points)
      bonus_points = calculate_bonus_score(comment.body_markdown)
      spaminess_rating = calculate_spaminess(comment)
      (rep_points + descendants_points + bonus_points - spaminess_rating).to_i
    end

    def calculate_spaminess(story, function_caller = FunctionCaller)
      # accepts comment or article as story
      return 100 unless story.user

      function_caller.call("blackbox-production-spamScore",
                           { story: story, user: story.user }.to_json).to_i
    end

    private

    def calculate_bonus_score(body_markdown)
      size_bonus = body_markdown.size > 200 ? 2 : 0
      code_bonus = body_markdown.include?("`") ? 1 : 0
      size_bonus + code_bonus
    end
  end
end
