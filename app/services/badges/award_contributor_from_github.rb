module Badges
  class AwardContributorFromGithub
    BADGE_SLUG = "dev-contributor".freeze

    REPOSITORIES = [
      "forem/forem",
      "forem/forem-browser-extension",
      "thepracticaldev/DEV-Android",
      "thepracticaldev/DEV-ios",
    ].freeze

    def self.call(since = 1.day.ago, msg = "Thank you so much for your contributions!")
      badge = Badge.find_by(slug: BADGE_SLUG)
      return unless badge

      REPOSITORIES.each do |repo|
        commits = Github::OauthClient.new.commits(repo, since: since.utc.iso8601)

        authors_uids = commits.map { |commit| commit.author.id }
        Identity.github.where(uid: authors_uids).find_each do |i|
          BadgeAchievement
            .where(user_id: i.user_id, badge_id: badge.id)
            .first_or_create(rewarding_context_message_markdown: msg)
        end
      end
    end
  end
end
