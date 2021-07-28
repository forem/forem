module Badges
  class AwardContributorFromGithub
    BADGE_SLUGS = {
      "dev-contributor": 1,
      "dev-contributor-bronze": 4,
      "dev-contributor-silver": 8,
      "dev-contributor-gold": 16
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
    end

    def call
      REPOSITORIES.each do |repo|
        commits = Github::OauthClient.new.commits(repo)
        commit_authors_with_count = commits.each_with_object(Hash.new(0)) do |commit, hash|
          hash[commit.author.id.to_s] += 1 unless commit.author.nil?
        end
        Identity.github.where(uid: commit_authors_with_count.keys).find_each do |identity|
          create_badges_for_user(identity.user_id, commit_authors_with_count[identity.uid])
        end
      end
    end

    private

    attr_reader :msg

    def create_badges_for_user(user_id, commits_count)
      BADGE_SLUGS.each do |slug, milestone|
        create_badge_achievement(user_id, slug, milestone, commits_count)
      end
    end

    def create_badge_achievement(user_id, slug, milestone, commits_count)
      return unless (badge_id = Badge.id_for_slug(slug))
      return if commits_count < milestone

      user_id_from_badges = BadgeAchievement.where(badge_id: badge_id).pluck(:user_id)
      BadgeAchievement.create(user_id: user_id, badge_id: badge_id) unless user_id_from_badges.include?(user_id)
    end
  end
end
