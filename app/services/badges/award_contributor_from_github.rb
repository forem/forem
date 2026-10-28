module Badges
  class AwardContributorFromGithub
    # Raised internally when a PR search still hits the rate limit after
    # exhausting its retries. Signals the run to stop; remaining candidates are
    # rederived from GitHub and picked up on the next scheduled run.
    class SearchBudgetExhausted < StandardError; end

    BADGE_SLUGS = {
      "dev-contributor": 1,
      "4x-commit-club": 4,
      "8x-commit-club": 8,
      "16x-commit-club": 16,
      "32x-commit-club": 32
    }.freeze

    # Highest contribution count any badge requires. Once a user's commit count
    # reaches this, a merged-PR lookup can never raise their score into a higher
    # tier, so the paced Search API call is skipped for them.
    MAX_BADGE_THRESHOLD = BADGE_SLUGS.values.max

    # This service authenticates with OAuth App client_id/client_secret (no user
    # access token; see #search_client), which GitHub subjects to the lower
    # unauthenticated-style Search API limit of 10 requests per minute rather
    # than the 30/min allowed for user-authenticated requests. Pace per-identity
    # PR searches to that 10/min ceiling so a run over many identities does not
    # burst past the limit and trip the rate limiter.
    SEARCH_REQUESTS_PER_MINUTE = 10
    SEARCH_MIN_INTERVAL = (60.0 / SEARCH_REQUESTS_PER_MINUTE).seconds.freeze
    # When a search is still rate limited, wait for the next limit window before
    # retrying rather than giving up and leaving the identity with a zero count.
    SEARCH_RATE_LIMIT_WAIT = 60.seconds.freeze
    # Transient server errors (5xx) are retried with a short backoff instead of
    # being recorded as a zero PR count on the first failure.
    SEARCH_SERVER_ERROR_WAIT = 5.seconds.freeze
    SEARCH_MAX_ATTEMPTS = 3

    # GitHub's Search API returns at most 100 results per page and caps any
    # single query at 1000 total results (10 pages). To gather *every* author who
    # has ever had a PR merged - not just recent ones - we walk the full history
    # in dated slices (see MERGED_PR_SLICE), each small enough to stay under that
    # 1000-result ceiling, and page through each slice.
    SEARCH_PR_AUTHOR_PAGE_SIZE = 100
    SEARCH_PR_AUTHOR_MAX_PAGES = 10
    # Width of each dated slice of merged-PR history. Chosen so a single slice is
    # very unlikely to contain more than 1000 merged PRs (GitHub's per-query
    # result cap); narrower slices cost more requests but guarantee completeness.
    MERGED_PR_SLICE = 30.days
    # Earliest date the full-history backfill scans from. forem/forem predates
    # this, but no PR was merged before it, so starting here avoids scanning empty
    # slices back to the epoch.
    MERGED_PR_HISTORY_START = Date.new(2018, 1, 1)
    # Fallback look-back for an hourly run when no scan marker is set yet (i.e. no
    # backfill has run). Keeps a fresh instance working - recent contributors are
    # still picked up - while the one-time rake backfill covers the deep history.
    MERGED_PR_FALLBACK_WINDOW = 14.days
    # Safety overlap subtracted from the stored marker on each hourly run so a PR
    # merged right around the previous run's boundary is not missed between runs.
    MERGED_PR_SCAN_OVERLAP = 2.days

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

    # GitHub usernames: 1-39 chars, alphanumeric or single hyphens (not leading,
    # trailing, or consecutive). Validating before building the Search query
    # prevents a blank or malformed nickname from producing an empty `author:`
    # qualifier, which GitHub would ignore and match every merged PR in the repo.
    GITHUB_USERNAME_REGEX = /\A[a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}\z/i

    REPOSITORIES = [
      "forem/forem"
    ].freeze

    def self.call(msg = I18n.t("services.badges.thank_you"))
      new(msg).call
    end

    # One-time (or occasional) full-history backfill. Walks every merged PR from
    # MERGED_PR_HISTORY_START to today to seed badges for long-standing
    # contributors, then records the scan marker so subsequent hourly #call runs
    # only scan forward from here. Intended to be invoked from a rake task.
    def self.backfill(msg = I18n.t("services.badges.thank_you"))
      new(msg, full_history: true).call
    end

    def initialize(msg, full_history: false)
      @msg = msg
      @full_history = full_history
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
      # Map uid (as String) -> commit contribution count for O(1) lookup.
      contributions_map = Github::OauthClient.new.contributors(repo).each_with_object({}) do |c, hash|
        hash[c.id.to_s] = c.contributions
      end

      # Resolve only the GitHub identities that could plausibly earn a badge for
      # this repo rather than scanning the entire Identity.github table (1M+ rows
      # in production, almost all with zero PRs here). Candidates come from GitHub
      # itself: commit contributors unioned with the authors of PRs merged within
      # the scan window. A backfill run scans the full history; an hourly run only
      # scans forward from the persisted marker, so the deep history is read once
      # rather than every hour. The PR-author union covers contributors with
      # merged PRs but no attributed commits, who the contributors endpoint omits.
      today = Time.current.utc.to_date
      scan_start = scan_start_date(today)

      candidate_uids = contributions_map.keys.to_set
      candidate_uids.merge(merged_pr_author_uids(repo, scan_start, today))

      Identity.github.where(uid: candidate_uids.to_a).find_each do |identity|
        process_candidate_identity(repo, identity, contributions_map)
      end

      # Only advance the marker once the scan for this window completed without
      # running out of Search budget, so an aborted run re-scans the same window
      # next time instead of skipping past unscanned dates. NOTE: the marker is
      # global; it assumes REPOSITORIES has a single entry. If more repos are
      # added, make the marker per-repo so one repo does not advance it past
      # another's unscanned window.
      Settings::General.github_contributor_prs_scanned_through = today.iso8601
    rescue SearchBudgetExhausted => e
      # Out of Search API budget for this run. The marker is left unchanged, so
      # the next scheduled run re-scans this window; nothing is skipped
      # permanently since the candidate set is rederived from GitHub each time.
      Rails.logger.warn("[Badges::AwardContributorFromGithub] stopping run early: #{e.message}")
    end

    # Determines the earliest merge date to scan for candidate PR authors.
    # - Backfill run: the full history start.
    # - Hourly run with a marker: just before the marker (minus a small overlap)
    #   so PRs merged near the previous boundary are not missed between runs.
    # - Hourly run with no marker yet (no backfill done): a short recent window so
    #   a fresh instance still awards recent contributors.
    def scan_start_date(today)
      return MERGED_PR_HISTORY_START if @full_history

      marker = Settings::General.github_contributor_prs_scanned_through.presence
      if marker
        Date.iso8601(marker) - MERGED_PR_SCAN_OVERLAP.in_days.to_i
      else
        today - MERGED_PR_FALLBACK_WINDOW.in_days.to_i
      end
    rescue ArgumentError
      # Corrupt marker value: fall back to the recent window rather than failing.
      today - MERGED_PR_FALLBACK_WINDOW.in_days.to_i
    end

    def process_candidate_identity(repo, identity, contributions_map)
      commits_count = contributions_map[identity.uid] || 0

      # Short-circuit the paced Search API call when it cannot change the outcome:
      # the commit count already clears the top badge threshold, or the user
      # already holds every badge we could award. This keeps the expensive,
      # rate-limited search to the handful of users for whom it actually matters.
      pr_count =
        if search_pr_count_needed?(identity.user_id, commits_count)
          github_user = github_nickname(identity)
          github_user ? merged_pr_count(repo, github_user) : 0
        else
          0
        end

      create_badges_for_user(identity.user_id, [commits_count, pr_count].max)
    end

    # True only when a merged-PR lookup could still award a badge the user does
    # not already have: the commit count falls short of the highest threshold and
    # at least one badge slug remains unawarded for this user.
    def search_pr_count_needed?(user_id, commits_count)
      return false if commits_count >= MAX_BADGE_THRESHOLD

      awarded_badge_ids = BadgeAchievement.where(user_id: user_id, badge_id: badge_slugs_with_id.values).pluck(:badge_id)
      awarded_badge_ids.size < badge_slugs_with_id.size
    end

    # Collects the uids of users who had a PR merged in the repo between
    # scan_start and scan_end (inclusive). GitHub's Search API caps a single
    # query at 1000 results, so the range is walked in dated slices
    # (MERGED_PR_SLICE wide) and each slice is paged through. Returns a Set of uid
    # Strings. Errors on any slice/page degrade gracefully (that page is skipped)
    # so the run still proceeds with whatever authors were gathered plus the
    # commit contributors.
    def merged_pr_author_uids(repo, scan_start, scan_end)
      uids = Set.new
      slice_days = MERGED_PR_SLICE.in_days.to_i
      slice_start = scan_start

      while slice_start <= scan_end
        slice_end = [slice_start + (slice_days - 1), scan_end].min
        gather_slice_author_uids(repo, slice_start, slice_end, uids)
        slice_start = slice_end + 1
      end

      uids
    end

    # Pages through one dated slice of merged PRs, adding each PR author's uid to
    # the shared set. A slice narrower than MERGED_PR_SLICE keeps each query under
    # GitHub's 1000-result cap; if a slice ever exceeds it, SEARCH_PR_AUTHOR_MAX_PAGES
    # still bounds the paging so the run stays within its request budget.
    def gather_slice_author_uids(repo, slice_start, slice_end, uids)
      range = "#{slice_start.iso8601}..#{slice_end.iso8601}"
      query = "repo:#{repo} is:pr is:merged merged:#{range}"

      (1..SEARCH_PR_AUTHOR_MAX_PAGES).each do |page|
        items = search_merged_pr_page(query, page)
        uids.merge(items.filter_map { |item| item.user&.id&.to_s })
        # Fewer than a full page means we reached the end of this slice.
        break if items.size < SEARCH_PR_AUTHOR_PAGE_SIZE
      end
    end

    # Fetches one paced page of merged-PR search results. Returns the page's
    # items, or an empty array on error so paging stops without aborting the run.
    def search_merged_pr_page(query, page)
      throttle_search
      search_client.search_issues(query, per_page: SEARCH_PR_AUTHOR_PAGE_SIZE, page: page).items
    rescue Github::Errors::Error => e
      Rails.logger.warn(
        "[Badges::AwardContributorFromGithub] could not list merged PR authors " \
        "for #{query} (page #{page}): #{e.message}",
      )
      []
    end

    # Counts merged PRs authored by github_user via the Search API, pacing calls
    # to stay within the authenticated rate limit. On a rate-limit response it
    # waits for the next window and retries rather than returning a zero count.
    def merged_pr_count(repo, github_user)
      query = "repo:#{repo} author:#{github_user} is:merged is:pr"

      SEARCH_MAX_ATTEMPTS.times do |attempt|
        last_attempt = attempt == SEARCH_MAX_ATTEMPTS - 1
        count = attempt_merged_pr_count(query, github_user, last_attempt)
        return count if count
      end

      0
    end

    # Performs a single paced Search API call. Returns the merged PR count on
    # success, or nil when a retryable error occurred and the loop should retry.
    def attempt_merged_pr_count(query, github_user, last_attempt)
      throttle_search
      # per_page: 1 keeps the single fetched page minimal since only total_count
      # is read; auto-pagination is disabled on the memoized client (see
      # #search_client) so Octokit does not follow rels[:next] across every page.
      search_client.search_issues(query, per_page: 1).total_count
    rescue Github::Errors::Error => e
      handle_search_error(e, github_user, last_attempt) == :retry ? nil : 0
    end

    # Memoized client dedicated to the Search API. Octokit.auto_paginate is
    # enabled globally (config/initializers/octokit.rb), which would make
    # search_issues follow rels[:next] across up to 10 pages and concatenate all
    # items in memory even though we only need total_count. Disable it on this
    # instance and reuse the single client across all identities/attempts rather
    # than instantiating a fresh Octokit::Client on every call.
    def search_client
      @search_client ||= Github::OauthClient.new.tap do |client|
        client.auto_paginate = false
      end
    end

    def handle_search_error(e, github_user, last_attempt)
      if search_rate_limited?(e)
        # Out of retries: stop the whole batch rather than sleeping uselessly
        # on the final attempt and recording a zero PR count for this identity.
        if last_attempt
          raise SearchBudgetExhausted,
                "rate limited for #{github_user} after #{SEARCH_MAX_ATTEMPTS} attempts"
        end

        Rails.logger.warn(
          "[Badges::AwardContributorFromGithub] PR search rate limited for " \
          "#{github_user}, waiting #{SEARCH_RATE_LIMIT_WAIT.to_i}s",
        )
        sleep(SEARCH_RATE_LIMIT_WAIT)
        @last_search_at = nil
        # Returning :retry to indicate we should continue the loop
        return :retry
      elsif e.is_a?(Github::Errors::ServerError) && !last_attempt
        Rails.logger.warn(
          "[Badges::AwardContributorFromGithub] PR search server error for " \
          "#{github_user}, retrying in #{SEARCH_SERVER_ERROR_WAIT.to_i}s: #{e.message}",
        )
        sleep(SEARCH_SERVER_ERROR_WAIT)
        @last_search_at = nil
        return :retry
      end

      Rails.logger.error("[Badges::AwardContributorFromGithub] PR search failed for #{github_user}: #{e.message}")
      0
    end

    def throttle_search
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      if @last_search_at
        elapsed = now - @last_search_at
        remaining = SEARCH_MIN_INTERVAL.to_f - elapsed
        sleep(remaining) if remaining.positive?
      end
      @last_search_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

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

      nickname =
        if info.respond_to?(:nickname)
          info.nickname
        elsif info.respond_to?(:[])
          info["nickname"] || info[:nickname]
        end

      # Reject blank or malformed nicknames so we never build a query with an
      # empty `author:` qualifier (which would match every merged PR in the repo).
      nickname = nickname.to_s.strip.presence
      return unless nickname&.match?(GITHUB_USERNAME_REGEX)

      nickname
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
