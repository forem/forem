module BadgeRewarder
  YEARS = { 1 => "one", 2 => "two", 3 => "three", 4 => "four", 5 => "five", 6 => "six", 7 => "seven" }.freeze
  REPOSITORIES = ["thepracticaldev/dev.to", "thepracticaldev/DEV-ios", "thepracticaldev/DEV-Android"].freeze

  LONGEST_STREAK_WEEKS = 16
  LONGEST_STREAK_MESSAGE = "16 weeks! You've achieved the longest writing " \
    "streak possible. This makes you eligible for special quests in the future. Keep up the amazing contributions to" \
    " our community!".freeze

  MINIMUM_QUALITY = -25

  def self.award_yearly_club_badges
    total_years = Time.current.year - SiteConfig.community_copyright_start_year.to_i
    (1..total_years).each do |i|
      message = "Happy #{SiteConfig.community_name} birthday! " \
        "Can you believe it's been #{i} #{'year'.pluralize(i)} already?!"
      badge = Badge.find_by(slug: "#{YEARS[i]}-year-club")
      next unless badge

      User.registered.where("created_at < ? AND created_at > ?", i.year.ago, i.year.ago - 2.days).find_each do |user|
        achievement = BadgeAchievement.create(
          user_id: user.id,
          badge_id: badge.id,
          rewarding_context_message_markdown: message,
        )
        user.save if achievement.valid?
      end
    end
  end

  def self.award_beloved_comment_badges(comment_count = 24)
    badge_id = Badge.find_by(slug: "beloved-comment")&.id
    return unless badge_id

    Comment.includes(:user).where("public_reactions_count > ?", comment_count).find_each do |comment|
      message = "You're famous! [This is the comment](#{URL.comment(comment)}) for which you are being recognized. 😄"
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
      winning_article = Article.where("score > 100")
        .published
        .where.not(user_id: past_winner_user_ids)
        .order(score: :desc)
        .where("published_at > ?", 7.5.days.ago) # More than seven days, to have some wiggle room.
        .cached_tagged_with(tag).first
      if winning_article
        award_badges(
          [winning_article.user.username],
          tag.badge.slug,
          "Congratulations on posting the most beloved [##{tag.name}](#{URL.tag(tag)}) post " \
          "from the past seven days! " \
          "Your winning post was [#{winning_article.title}](#{URL.article(winning_article)}). " \
          "(You can only win once per badge-eligible tag)",
        )
      end
    end
  end

  def self.award_contributor_badges_from_github(since = 1.day.ago, msg = "Thank you so much for your contributions!")
    badge = Badge.find_by(slug: "dev-contributor")
    return unless badge

    REPOSITORIES.each do |repo|
      commits = Github::Client.commits(repo, since: since.utc.iso8601)

      authors_uids = commits.map { |commit| commit.author.id }
      Identity.github.where(uid: authors_uids).find_each do |i|
        BadgeAchievement.where(user_id: i.user_id, badge_id: badge.id).first_or_create(
          rewarding_context_message_markdown: msg,
        )
      end
    end
  end

  def self.award_four_week_streak_badge
    award_streak_badge(4)
  end

  def self.award_eight_week_streak_badge
    award_streak_badge(8)
  end

  def self.award_sixteen_week_streak_badge
    award_streak_badge(16)
  end

  def self.award_streak_badge(num_weeks)
    # No credit for super low quality
    article_user_ids = Article.published
      .where("published_at > ? AND score > ?", 1.week.ago, MINIMUM_QUALITY)
      .pluck(:user_id)
    message = if num_weeks == LONGEST_STREAK_WEEKS
                LONGEST_STREAK_MESSAGE
              else
                "Congrats on achieving this streak! Consistent writing is hard. " \
                "The next streak badge you can get is the #{num_weeks * 2} Week Badge. 😉"
              end
    users = User.where(id: article_user_ids).where("articles_count >= ?", num_weeks)
    usernames = []
    users.find_each do |user|
      count = 0
      num_weeks.times do |i|
        num = i + 1
        count += 1 if user.articles.published.where("published_at > ? AND published_at < ?", num.weeks.ago,
                                                    (num - 1).weeks.ago).any?
      end
      usernames << user.username if count >= num_weeks
    end
    award_badges(usernames, "#{num_weeks}-week-streak", message)
  end

  def self.award_badges(usernames, slug, message_markdown)
    badge_id = Badge.find_by(slug: slug)&.id
    return unless badge_id

    User.registered.where(username: usernames).find_each do |user|
      BadgeAchievement.create(
        user_id: user.id,
        badge_id: badge_id,
        rewarding_context_message_markdown: message_markdown,
      )
      user.save
    end
  end
end
