class BlackBox
  def self.article_hotness_score(article)
    return (article.featured_number || 10000) / 10000 unless Rails.env.production?
    reaction_points = article.reactions.sum(:points)
    recency_bonus = article.published_at > 12.hours.ago ? 50 : 0
    today_bonus = article.published_at > 36.hours.ago ? 250 : 0
    FunctionCaller.new("blackbox-production-articleHotness",
      { article: article, user: article.user }.to_json).call +
      reaction_points + recency_bonus + today_bonus
  end

  def self.comment_quality_score(comment)
    descendants_points = (comment.descendants.size / 2)
    rep_points = comment.reactions.sum(:points)
    bonus_points = calculate_bonus_score(comment.body_markdown)
    spaminess_rating = calculate_spaminess(comment)
    (rep_points + descendants_points + bonus_points - spaminess_rating).to_i
  end

  def self.calculate_spaminess(story)
    # accepts comment or article as story
    return 0 unless Rails.env.production?
    return 100 unless story.user
    FunctionCaller.new("blackbox-production-spamScore",
      { story: story, user: story.user }.to_json).call
  end

  private

  def self.calculate_bonus_score(body_markdown)
    size_bonus = body_markdown.size > 200 ? 2 : 0
    code_bonus = body_markdown.include?("`") ? 1 : 0
    size_bonus + code_bonus
  end
end
