module Badges
  class AwardContributorFromGithub
    BADGE_SLUGS = {
      "dev-contributor": 1,
      "4x-commit-club": 4,
      "8x-commit-club": 8,
      "16x-commit-club": 16,
      "32x-commit-club": 32
    }.freeze

    REPOSITORIES = [
      "forem/forem",
      "forem/forem-browser-extension",
      "forem/DEV-Android",
      "forem/DEV-ios",
    ].freeze

    def self.call(msg = I18n.t("services.badges.thank_you"))
      new(msg).call
    end

    def initialize(msg)
      @msg = msg
      @badge_slugs_with_id = get_badge_slugs_with_id
    end

    def call
      return unless Settings::Authentication.providers.include?(:github)

      REPOSITORIES.each do |repo|
        award_single_commit_contributors(repo)
        award_multi_commit_contributors(repo)
      end
    end

    private

    attr_reader :msg, :badge_slugs_with_id

    def award_single_commit_contributors(repo)
      yesterday = 1.day.ago.utc.iso8601
      commits = Github::OauthClient.new.commits(repo, since: yesterday)
      authors_uids = commits.map { |commit| commit.author.id }
      Identity.github.where(uid: authors_uids).find_each do |i|
        BadgeAchievement
          .where(user_id: i.user_id, badge_id: badge_slugs_with_id[:"dev-contributor"])
          .first_or_create(rewarding_context_message_markdown: msg)
      end
    end

    def award_multi_commit_contributors(repo)
      contributors = Github::OauthClient.new.contributors(repo)
      authors_uids = contributors.map(&:id)

      Identity.github.where(uid: authors_uids).find_each do |identity|
        user_contribution = contributors.detect { |contributor| contributor.id.to_s == identity.uid }
        next if user_contribution.nil?

        create_badges_for_user(identity.user_id, user_contribution.contributions)
      end
    end

    def create_badges_for_user(user_id, commits_count)
      badge_slugs_with_id.each do |slug, slug_id|
        next if commits_count < BADGE_SLUGS[slug]

        BadgeAchievement.create(user_id: user_id, badge_id: slug_id)
      end
    end

    def get_badge_slugs_with_id
      badge_slugs_with_id = {}
      BADGE_SLUGS.each_key do |slug|
        badge_slugs_with_id[slug] = Badge.id_for_slug(slug)
      end
      badge_slugs_with_id.compact
    end
  end
end
