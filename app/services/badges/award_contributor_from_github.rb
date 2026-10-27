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
      "forem/forem"
    ].freeze

    def self.call(msg = I18n.t("services.badges.thank_you"))
      new(msg).call
    end

    def initialize(msg)
      @msg = msg
    end

    def call
      return unless Settings::Authentication.providers.map(&:to_s).include?("github")

      @badge_slugs_with_id = get_badge_slugs_with_id

      REPOSITORIES.each do |repo|
        award_single_commit_contributors(repo)
        award_multi_commit_contributors(repo)
      end
    end

    private

    attr_reader :msg, :badge_slugs_with_id

    def award_single_commit_contributors(repo)
      dev_contributor_badge_id = badge_slugs_with_id[:"dev-contributor"]
      return unless dev_contributor_badge_id

      yesterday = 1.day.ago.utc.iso8601
      commits = Github::OauthClient.new.commits(repo, since: yesterday)
      authors_uids = commits.filter_map { |commit| commit.author&.id }
      Identity.github.where(uid: authors_uids).find_each do |i|
        BadgeAchievement
          .where(user_id: i.user_id, badge_id: dev_contributor_badge_id)
          .first_or_create(rewarding_context_message_markdown: msg)
      end
    end

    def award_multi_commit_contributors(repo)
      contributors = Github::OauthClient.new.contributors(repo)
      # Map uid -> contribution count for O(1) lookup
      contributions_map = contributors.each_with_object({}) do |c, hash|
        hash[c.id.to_s] = c.contributions
      end

      # Iterate over all GitHub identities rather than only those present in the
      # contributors response. GitHub's contributors endpoint lists commit authors
      # only, so an identity with merged PRs but no attributed commits would never
      # appear here and its PR count (the fallback below) would never be checked.
      Identity.github.find_each do |identity|
        commits_count = contributions_map[identity.uid] || 0

        # Use Search API to count merged PRs as a fallback/complement to commit counts
        # this helps contributors who may have attribution issues with commit counts
        pr_count = 0
        github_user = identity.auth_data_dump&.info&.nickname
        if github_user
          query = "repo:#{repo} author:#{github_user} is:merged is:pr"
          begin
            search_results = Github::OauthClient.new.search_issues(query)
            pr_count = search_results.total_count
          rescue => e
            Rails.logger.error("[Badges::AwardContributorFromGithub] PR search failed for #{github_user}: #{e.message}")
          end
        end

        contribution_score = [commits_count, pr_count].max
        create_badges_for_user(identity.user_id, contribution_score)
      end
    end

    def create_badges_for_user(user_id, commits_count)
      badge_slugs_with_id.each do |slug, slug_id|
        next if slug_id.nil?
        next if commits_count < BADGE_SLUGS[slug]

        BadgeAchievement
          .where(user_id: user_id, badge_id: slug_id)
          .first_or_create(rewarding_context_message_markdown: msg)
      end
    end

    def get_badge_slugs_with_id
      badge_slugs_with_id = {}
      missing_slugs = []

      BADGE_SLUGS.each_key do |slug|
        if (slug_id = Badge.id_for_slug(slug))
          badge_slugs_with_id[slug] = slug_id
        else
          missing_slugs << slug
        end
      end

      log_missing_slugs(missing_slugs) if missing_slugs.any?
      badge_slugs_with_id
    end

    def log_missing_slugs(slugs)
      Rails.logger.info("[Badges::AwardContributorFromGithub] Badge slugs not found: #{slugs.join(', ')}")
    end
  end
end
