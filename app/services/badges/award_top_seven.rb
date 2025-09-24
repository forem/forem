module Badges
  class AwardTopSeven
    BADGE_SLUG = "top-7".freeze
    MAX_REPUTATION_MODIFIER = 4.0

    def self.call(usernames, message_markdown = default_message_markdown)
      users = User.where(username: usernames)
      
      users.each do |user|
        # Apply reputation modifier changes for this user
        apply_reputation_modifier_changes(user)
      end

      ::Badges::Award.call(
        users,
        BADGE_SLUG,
        message_markdown,
      )
    end

    def self.default_message_markdown
      I18n.t("services.badges.congrats", community: Settings::Community.community_name)
    end

    private

    def self.apply_reputation_modifier_changes(badge_recipient)
      # Double the badge recipient's reputation modifier (max 4.0)
      new_recipient_modifier = [badge_recipient.reputation_modifier * 2.0, MAX_REPUTATION_MODIFIER].min
      badge_recipient.update!(reputation_modifier: new_recipient_modifier)

      # Find users who reacted positively to this user's articles in the last week
      positive_reactors = find_positive_reactors_to_user_articles(badge_recipient)
      
      # Apply 1.5x reputation modifier to positive reactors (max 4.0)
      positive_reactors.each do |reactor|
        new_modifier = [reactor.reputation_modifier * 1.5, MAX_REPUTATION_MODIFIER].min
        reactor.update!(reputation_modifier: new_modifier)
      end

      Rails.logger.info "Applied reputation modifier changes for Top 7 badge recipient: #{badge_recipient.username}"
      Rails.logger.info "Updated #{positive_reactors.count} positive reactors' reputation modifiers"
    end

    def self.find_positive_reactors_to_user_articles(user)
      # Get the user's articles from the last week
      user_articles = user.articles.where(created_at: 1.week.ago..Time.current)
      
      # Find all positive reactions to these articles
      positive_reaction_categories = ReactionCategory.list.select(&:positive?).map(&:slug)
      
      # Get unique users who reacted positively to these articles
      User.joins(:reactions)
          .where(reactions: {
            reactable_type: 'Article',
            reactable_id: user_articles.pluck(:id),
            category: positive_reaction_categories,
            created_at: 1.week.ago..Time.current
          })
          .distinct
    end
  end
end
