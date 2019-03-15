module BadgeRewarder
  def self.award_yearly_club_badges
    award_one_year_badges
    award_two_year_badges
    award_three_year_badges
  end

  def self.award_beloved_comment_badges
    Comment.where("positive_reactions_count > ?", 24).find_each do |comment|
      message = "You're DEV famous! [This is the comment](https://dev.to#{comment.path}) for which you are being recognized. 😄"
      achievement = BadgeAchievement.create(
        user_id: comment.user_id,
        badge_id: Badge.find_by_slug("beloved-comment")&.id || 3,
        rewarding_context_message_markdown: message,
      )
      comment.user.save if achievement.valid?
      # ID 3 is the proper ID in prod. We should change in future to ENV var.
    end
  end

  def self.award_top_seven_badges(usernames, message_markdown = "Congrats!!!")
    award_badges(usernames, "top-7", message_markdown)
  end

  def self.award_fab_five_badges(usernames, message_markdown = "Congrats!!!")
    award_badges(usernames, "fab-5", message_markdown)
  end

  def self.award_contributor_badges(usernames, message_markdown = "Thank you so much for your contributions!")
    award_badges(usernames, "dev-contributor", message_markdown)
  end

  def self.award_contributor_badges_from_github(since = 1.day.ago, message_markdown = "Thank you so much for your contributions!")
    client = Octokit::Client.new
    badge = Badge.find_by_slug("dev-contributor")
    ["thepracticaldev/dev.to", "thepracticaldev/DEV-ios"].each do |repo|
      commits = client.commits repo, since: since.iso8601
      authors_uids = commits.map { |c| c.author.id }
      Identity.where(provider: "github", uid: authors_uids).find_each do |i|
        BadgeAchievement.where(user_id: i.user_id, badge_id: badge.id).first_or_create(
          rewarding_context_message_markdown: message_markdown,
        )
      end
    end
  end

  def self.award_streak_badge(num_weeks)
    article_user_ids = Article.where(published: true).where("published_at > ? AND score > ?", 1.week.ago, -25).pluck(:user_id) # No cred for super low quality
    message = "Congrats on achieving this streak! Consistent writing is hard. The next streak badge you can get is the #{num_weeks * 2} Week Badge. 😉"
    users = User.where(id: article_user_ids).where("articles_count >= ?", num_weeks)
    usernames = []
    users.find_each do |user|
      count = 0
      num_weeks.times do |i|
        num = i + 1
        count += 1 if user.articles.where("published_at > ? AND published_at < ?", num.weeks.ago, (num - 1).weeks.ago).any?
      end
      usernames << user.username if count >= num_weeks
    end
    award_badges(usernames, "#{num_weeks}-week-streak", message)
  end

  def self.award_badges(usernames, slug, message_markdown)
    User.where(username: usernames).find_each do |user|
      BadgeAchievement.create(
        user_id: user.id,
        badge_id: Badge.find_by_slug(slug).id,
        rewarding_context_message_markdown: message_markdown,
      )
      user.save
    end
  end

  def self.award_one_year_badges
    message = "Happy DEV birthday!"
    User.where("created_at < ? AND created_at > ?", 1.year.ago, 367.days.ago).find_each do |user|
      achievement = BadgeAchievement.create(
        user_id: user.id,
        badge_id: Badge.find_by_slug("one-year-club").id,
        rewarding_context_message_markdown: message,
      )
      user.save if achievement.valid?
    end
  end

  def self.award_two_year_badges
    message = "Happy DEV birthday! Can you believe it's been two years?"
    User.where("created_at < ? AND created_at > ?", 2.year.ago, 732.days.ago).find_each do |user|
      achievement = BadgeAchievement.create(
        user_id: user.id,
        badge_id: Badge.find_by_slug("two-year-club").id,
        rewarding_context_message_markdown: message,
      )
      user.save if achievement.valid?
    end
  end

  def self.award_three_year_badges
    message = "Happy DEV birthday! Can you believe it's been three years already?!"
    User.where("created_at < ? AND created_at > ?", 3.year.ago, 1097.days.ago).find_each do |user|
      achievement = BadgeAchievement.create(
        user_id: user.id,
        badge_id: Badge.find_by_slug("three-year-club").id,
        rewarding_context_message_markdown: message,
      )
      user.save if achievement.valid?
    end
  end
end
