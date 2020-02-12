module BadgeRewarder
  YEARS = { 1 => "one", 2 => "two", 3 => "three", 4 => "four", 5 => "five", 6 => "six", 7 => "seven", 8 => "eight", 9 => "nine", 10 => "ten" }.freeze

  def self.award_yearly_club_badges
    (1..3).each do |i|
      message = "Happy DEV birthday! Can you believe it's been #{i} #{'year'.pluralize(i)} already?!"
      badge = Badge.find_by!(slug: "#{YEARS[i]}-year-club")
      User.where("created_at < ? AND created_at > ?", i.year.ago, i.year.ago - 2.days).find_each do |user|
        achievement = BadgeAchievement.create(
          user_id: user.id,
          badge_id: badge.id,
          rewarding_context_message_markdown: message,
        )
        user.save if achievement.valid?
      end
    end
  end

  def self.award_beloved_comment_badges
    # ID 3 is the proper ID in prod. We should change in future to ENV var.
    badge_id = Badge.find_by(slug: "beloved-comment")&.id || 3
    Comment.where("positive_reactions_count > ?", 24).find_each do |comment|
      message = "You're famous! [This is the comment](https://#{ApplicationConfig['APP_DOMAIN']}#{comment.path}) for which you are being recognized. 😄"
      achievement = BadgeAchievement.create(
        user_id: comment.user_id,
        badge_id: badge_id,
        rewarding_context_message_markdown: message,
      )
      comment.user.save if achievement.valid?
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

  def self.award_tag_badges
    Tag.where.not(badge_id: nil).find_each do |tag|
      past_winner_user_ids = BadgeAchievement.where(badge_id: tag.badge_id).pluck(:user_id)
      winning_article = Article.where("score > 100").
        published.
        where.not(user_id: past_winner_user_ids).
        order("score DESC").
        where("published_at > ?", 7.5.days.ago). # More than seven days, to have some wiggle room.
        cached_tagged_with(tag).first
      if winning_article
        award_badges(
          [winning_article.user.username],
          tag.badge.slug,
          "Congratulations on posting the most beloved [##{tag.name}](#{ApplicationConfig['APP_PROTOCOL'] + ApplicationConfig['APP_DOMAIN']}/t/#{tag.name}) post from the past seven days! Your winning post was [#{winning_article.title}](#{ApplicationConfig['APP_PROTOCOL'] + ApplicationConfig['APP_DOMAIN'] + winning_article.path}). (You can only win once per badge-eligible tag)",
        )
      end
    end
  end

  def self.award_contributor_badges_from_github(since = 1.day.ago, message_markdown = "Thank you so much for your contributions!")
    client = Octokit::Client.new
    badge = Badge.find_by!(slug: "dev-contributor")
    ["thepracticaldev/dev.to", "thepracticaldev/DEV-ios", "thepracticaldev/DEV-Android"].each do |repo|
      commits = client.commits repo, since: since.iso8601
      authors_uids = commits.map { |commit| commit.author.id }
      Identity.where(provider: "github", uid: authors_uids).find_each do |i|
        BadgeAchievement.where(user_id: i.user_id, badge_id: badge.id).first_or_create(
          rewarding_context_message_markdown: message_markdown,
        )
      end
    end
  end

  def self.award_streak_badge(num_weeks)
    article_user_ids = Article.published.where("published_at > ? AND score > ?", 1.week.ago, -25).pluck(:user_id) # No cred for super low quality
    message = if num_weeks == 16
                "16 weeks! You've achieved the longest DEV writing streak possible. This makes you eligible for special quests in the future. Keep up the amazing contributions to our community!"
              else
                "Congrats on achieving this streak! Consistent writing is hard. The next streak badge you can get is the #{num_weeks * 2} Week Badge. 😉"
              end
    users = User.where(id: article_user_ids).where("articles_count >= ?", num_weeks)
    usernames = []
    users.find_each do |user|
      count = 0
      num_weeks.times do |i|
        num = i + 1
        count += 1 if user.articles.published.where("published_at > ? AND published_at < ?", num.weeks.ago, (num - 1).weeks.ago).any?
      end
      usernames << user.username if count >= num_weeks
    end
    award_badges(usernames, "#{num_weeks}-week-streak", message)
  end

  def self.award_badges(usernames, slug, message_markdown)
    badge_id = Badge.find_by!(slug: slug).id
    User.where(username: usernames).find_each do |user|
      BadgeAchievement.create(
        user_id: user.id,
        badge_id: badge_id,
        rewarding_context_message_markdown: message_markdown,
      )
      user.save
    end
  end
end
