class BadgeRewarder
  def award_yearly_club_badges
    message = "Happy DEV birthday!"
    User.where("created_at < ? AND created_at > ?", 1.year.ago, 367.days.ago).each do |user|
      achievement = BadgeAchievement.create(
        user_id: user.id,
        badge_id: 2,
        rewarding_context_message_markdown: message)
      user.save if achievement.valid?
      # ID 2 is the proper ID in prod. We should change in future to ENV var.
    end
  end

  def award_beloved_comment_badges
    Comment.where("positive_reactions_count > ?", 24).each do |comment|
      message = "You're DEV famous! [This is the comment](https://dev.to#{comment.path}) for which you are being recognized. 😄"
      achievement = BadgeAchievement.create(
        user_id: comment.user_id,
        badge_id: 3,
        rewarding_context_message_markdown: message)
      comment.user.save if achievement.valid?
      # ID 3 is the proper ID in prod. We should change in future to ENV var.
    end
  end
end
