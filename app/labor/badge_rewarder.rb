class BadgeRewarder
  def award_yearly_club_badges
    message = "Happy DEV birthday!"
    User.where("created_at < ? AND created_at > ?",1.year.ago, 367.days.ago).each do |user|
      BadgeAchievement.create(user_id: user.id, badge_id: 2, rewarding_context_message: message)
      # ID 2 is the proper ID in prod. We should change in future to ENV var.
    end
  end
end
