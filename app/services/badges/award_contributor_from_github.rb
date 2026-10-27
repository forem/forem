module Badges
  class AwardContributorFromGithub
    BADGE_SLUGS = {
      "dev-contributor": 1,
      "4x-commit-club": 4,
      "8x-commit-club": 8,
      "16x-commit-club": 16,
      "32x-commit-club": 32
    }.freeze

    # GitHub's authenticated Search API allows 30 requests per minute. Space the
    # per-identity PR searches out so a run over many identities stays within
    # that limit instead of bursting and tripping the rate limiter.
    SEARCH_REQUESTS_PER_MINUTE = 30
    SEARCH_MIN_INTERVAL = (60.0 / SEARCH_REQUESTS_PER_MINUTE).seconds.freeze
    # When a search is still rate limited, wait for the next limit window before
    # retrying rather than giving up and leaving the identity with a zero count.
    SEARCH_RATE_LIMIT_WAIT = 60.seconds.freeze
    # Transient server errors (5xx) are retried with a short backoff instead of
    # being recorded as a zero PR count on the first failure.
    SEARCH_SERVER_ERROR_WAIT = 5.seconds.freeze
    SEARCH_MAX_ATTEMPTS = 3

    # Upper bound on how many GitHub identities a single run processes. The job
    # runs hourly; capping the batch keeps one run from issuing an unbounded
    # number of paced Search API calls (which, at ~2s each, would otherwise let a
    # large identity table push a run past the next scheduled run). The run
    # resumes from a persisted cursor so coverage still rotates through everyone.
    IDENTITY_BATCH_SIZE = 500

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

      # Iterate over GitHub identities rather than only those present in the
      # contributors response. GitHub's contributors endpoint lists commit authors
      # only, so an identity with merged PRs but no attributed commits would never
      # appear here and its PR count (the fallback below) would never be checked.
      #
      # Process at most IDENTITY_BATCH_SIZE identities per run, resuming after the
      # persisted cursor, so a single hourly run cannot issue an unbounded number
      # of paced Search API calls. The cursor rotates through the whole table.
      process_identity_batch(repo, contributions_map)
    end

    def process_identity_batch(repo, contributions_map)
      cursor = Settings::General.github_contributor_badge_last_identity_id.to_i
      identities = Identity.github.where("id > ?", cursor).order(:id).limit(IDENTITY_BATCH_SIZE).to_a

      # Reached the end of the table: wrap back to the start on the next run.
      if identities.empty? && cursor.positive?
        Settings::General.github_contributor_badge_last_identity_id = 0
        return
      end

      identities.each do |identity|
        commits_count = contributions_map[identity.uid] || 0

        # Use Search API to count merged PRs as a fallback/complement to commit counts
        # this helps contributors who may have attribution issues with commit counts
        github_user = github_nickname(identity)
        pr_count = github_user ? merged_pr_count(repo, github_user) : 0

        contribution_score = [commits_count, pr_count].max
        create_badges_for_user(identity.user_id, contribution_score)
      end

      advance_cursor(identities)
    end

    # Persist how far this run got. A full batch means more identities remain, so
    # resume after the last processed id; a short batch means we hit the end, so
    # reset to 0 to start over next run.
    def advance_cursor(identities)
      next_cursor = identities.size < IDENTITY_BATCH_SIZE ? 0 : identities.last.id
      Settings::General.github_contributor_badge_last_identity_id = next_cursor
    end

    # Counts merged PRs authored by github_user via the Search API, pacing calls
    # to stay within the authenticated rate limit. On a rate-limit response it
    # waits for the next window and retries rather than returning a zero count.
    def merged_pr_count(repo, github_user)
      query = "repo:#{repo} author:#{github_user} is:merged is:pr"

      SEARCH_MAX_ATTEMPTS.times do
        throttle_search
        search_results = Github::OauthClient.new.search_issues(query)
        return search_results.total_count
      rescue Github::Errors::Error => e
        if search_rate_limited?(e)
          Rails.logger.warn(
            "[Badges::AwardContributorFromGithub] PR search rate limited for " \
            "#{github_user}, waiting #{SEARCH_RATE_LIMIT_WAIT.to_i}s",
          )
          sleep(SEARCH_RATE_LIMIT_WAIT)
          @last_search_at = nil
          next
        elsif e.is_a?(Github::Errors::ServerError)
          Rails.logger.warn(
            "[Badges::AwardContributorFromGithub] PR search server error for " \
            "#{github_user}, retrying in #{SEARCH_SERVER_ERROR_WAIT.to_i}s: #{e.message}",
          )
          sleep(SEARCH_SERVER_ERROR_WAIT)
          @last_search_at = nil
          next
        end

        Rails.logger.error("[Badges::AwardContributorFromGithub] PR search failed for #{github_user}: #{e.message}")
        return 0
      end

      Rails.logger.error(
        "[Badges::AwardContributorFromGithub] PR search failed for " \
        "#{github_user} after #{SEARCH_MAX_ATTEMPTS} attempts (rate limit or server error)",
      )
      0
    end

    # Space successive Search API calls at least SEARCH_MIN_INTERVAL apart.
    def throttle_search
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      if @last_search_at
        elapsed = now - @last_search_at
        remaining = SEARCH_MIN_INTERVAL.to_f - elapsed
        sleep(remaining) if remaining.positive?
      end
      @last_search_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    # Rate limiting is classified first by HTTP status (429), then by error type:
    # the client maps Octokit's TooManyRequests/TooManyLoginAttempts to the
    # matching Github::Errors classes. GitHub's secondary rate limit is returned
    # as a 403 that Octokit surfaces as a generic Forbidden with no distinct type,
    # so for that case only we fall back to matching the documented message text.
    RATE_LIMIT_ERROR_TYPES = [
      Github::Errors::TooManyRequests,
      Github::Errors::TooManyLoginAttempts,
    ].freeze
    SECONDARY_RATE_LIMIT_MESSAGE = /secondary rate limit|abuse detection/i

    def search_rate_limited?(error)
      status = error.respond_to?(:response_status) ? error.response_status : nil
      return true if status == 429
      return true if RATE_LIMIT_ERROR_TYPES.any? { |type| error.is_a?(type) }

      status == 403 && error.message.to_s.match?(SECONDARY_RATE_LIMIT_MESSAGE)
    end

    # auth_data_dump is serialized YAML and may be an OmniAuth::AuthHash (responds
    # to #info) or a plain Hash. Support both when reading the GitHub nickname.
    def github_nickname(identity)
      dump = identity.auth_data_dump
      return if dump.blank?

      info =
        if dump.respond_to?(:info)
          dump.info
        elsif dump.respond_to?(:[])
          dump["info"] || dump[:info]
        end
      return if info.blank?

      if info.respond_to?(:nickname)
        info.nickname
      elsif info.respond_to?(:[])
        info["nickname"] || info[:nickname]
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
