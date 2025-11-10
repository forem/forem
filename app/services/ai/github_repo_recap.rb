module Ai
  ##
  # Generates an AI-powered recap of GitHub repository activity over a specified timeframe.
  # Fetches pull requests and commits from a GitHub repository and creates a markdown summary
  # focusing on significant changes while aggregating minor ones.
  #
  # @example Generate a weekly recap for a public repository
  #   recap = Ai::GithubRepoRecap.new("forem/forem", days_ago: 7)
  #   result = recap.generate
  #   
  #   if result
  #     puts result.title  # => "Weekly Recap: Major Performance Improvements"
  #     puts result.body   # => "## Major Changes\n{% embed https://github.com/... %}"
  #   else
  #     puts "No activity found"
  #   end
  #
  # @example Generate a monthly recap with custom GitHub client
  #   user = User.find_by(github_username: "username")
  #   client = Github::OauthClient.for_user(user)
  #   recap = Ai::GithubRepoRecap.new("org/repo", days_ago: 30, github_client: client)
  #   result = recap.generate
  class GithubRepoRecap
    RecapResult = Struct.new(:title, :body, keyword_init: true)

    # @param repo_name [String] The GitHub repository in "owner/name" format (e.g., "rails/rails")
    # @param days_ago [Integer] Number of days back to look for activity (default: 7)
    # @param github_client [Github::OauthClient] Optional GitHub client for dependency injection
    # @param ai_client [Ai::Base] Optional AI client for dependency injection
    def initialize(repo_name, days_ago: 7, github_client: nil, ai_client: nil)
      @repo_name = repo_name
      @days_ago = days_ago
      @since = days_ago.days.ago
      @github_client = github_client || Github::OauthClient.new
      @ai_client = ai_client || Ai::Base.new
    end

    ##
    # Generates the recap report.
    # Returns nil if there's no activity in the specified timeframe.
    #
    # @return [RecapResult, nil] A struct containing title and body, or nil if no activity
    def generate
      puts "\n==== Starting GitHub Repo Recap for #{repo_name} ===="
      puts "Timeframe: Last #{days_ago} days (since #{since})"
      
      puts "\n[1/4] Fetching GitHub activity..."
      activity_data = fetch_github_activity
      
      puts "\n[2/4] Checking for activity..."
      puts "  - PRs found: #{activity_data[:total_prs]}"
      puts "  - Commits found: #{activity_data[:total_commits]}"
      
      if no_activity?(activity_data)
        puts "  ✗ No activity found, returning nil"
        return nil
      end
      puts "  ✓ Activity found!"

      puts "\n[3/4] Building AI prompt..."
      prompt = build_recap_prompt(activity_data)
      puts "  ✓ Prompt built (#{prompt.length} characters)"
      
      puts "\n[4/4] Calling AI to generate recap..."
      response = @ai_client.call(prompt)
      puts "  ✓ AI response received (#{response.length} characters)"
      
      puts "\nParsing response..."
      result = parse_recap_response(response)
      puts "  ✓ Successfully generated recap: #{result.title}"
      puts "\n==== Recap Complete ===="
      
      result
    rescue StandardError => e
      puts "\n✗✗✗ ERROR: #{e.class} - #{e.message}"
      puts e.backtrace.first(5).join("\n")
      Rails.logger.error("GitHub Recap generation failed: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      nil
    end

    private

    attr_reader :repo_name, :days_ago, :since, :github_client, :ai_client

    ##
    # Fetches activity data from GitHub (pull requests and commits)
    #
    # @return [Hash] Hash containing pull requests and commits data
    def fetch_github_activity
      puts "  → Fetching merged pull requests..."
      pull_requests = fetch_merged_pull_requests
      puts "  ✓ Found #{pull_requests.size} merged PRs"
      
      puts "  → Fetching recent commits..."
      commits = fetch_recent_commits
      puts "  ✓ Found #{commits.size} commits"
      
      {
        pull_requests: pull_requests,
        commits: commits,
        total_prs: pull_requests.size,
        total_commits: commits.size
      }
    end

    ##
    # Fetches merged pull requests from the specified timeframe
    #
    # @return [Array<Sawyer::Resource>] Array of pull request objects
    def fetch_merged_pull_requests
      puts "    • Starting PR fetch loop..."
      merged_prs = []
      page = 1
      per_page = 100
      max_pages = 5
      
      # Fetch PRs in pages until we have enough that go back to our timeframe
      # or we've fetched a reasonable maximum
      loop do
        puts "    • Fetching page #{page} (per_page=#{per_page})..."
        start_time = Time.now
        
        # Use paginate method with explicit break to avoid auto-pagination hanging
        prs = with_manual_pagination do
          github_client.pull_requests(
            repo_name,
            state: "closed",
            sort: "updated",
            direction: "desc",
            per_page: per_page,
            page: page
          )
        end
        
        elapsed = (Time.now - start_time).round(2)
        puts "    • Page #{page} fetched in #{elapsed}s - got #{prs.size} PRs"
        
        break if prs.empty?
        
        # Filter for merged PRs
        batch_merged = prs.select { |pr| pr.merged_at }
        puts "    • #{batch_merged.size} of #{prs.size} PRs were merged"
        
        # Separate into ones within timeframe and ones before
        within_timeframe, before_timeframe = batch_merged.partition do |pr|
          Time.parse(pr.merged_at.to_s) >= since
        end
        
        puts "    • #{within_timeframe.size} within timeframe, #{before_timeframe.size} before"
        
        merged_prs.concat(within_timeframe)
        
        # Stop if:
        # - We found PRs before our timeframe (no need to look further back)
        # - We've reached max pages to avoid hanging
        # - We received fewer results than per_page (last page)
        if before_timeframe.any?
          puts "    • Stopping: found PRs before timeframe"
          break
        elsif page >= max_pages
          puts "    • Stopping: reached max pages (#{max_pages})"
          break
        elsif prs.size < per_page
          puts "    • Stopping: last page (got #{prs.size} < #{per_page})"
          break
        end
        
        page += 1
      end
      
      puts "    • Total merged PRs in timeframe: #{merged_prs.size}"
      merged_prs
    rescue Github::Errors::Error => e
      puts "    ✗ ERROR fetching PRs: #{e.message}"
      Rails.logger.error("Failed to fetch pull requests: #{e.message}")
      []
    end

    ##
    # Fetches recent commits from the repository
    #
    # @return [Array<Sawyer::Resource>] Array of commit objects
    def fetch_recent_commits
      puts "    • Starting commit fetch loop..."
      all_commits = []
      page = 1
      per_page = 100
      # Limit to max 300 commits to avoid excessive API calls and token limits
      max_commits = 300
      
      loop do
        puts "    • Fetching commits page #{page} (per_page=#{per_page}, since=#{since.iso8601})..."
        start_time = Time.now
        
        commits = with_manual_pagination do
          github_client.commits(
            repo_name,
            since: since.iso8601,
            per_page: per_page,
            page: page
          )
        end
        
        elapsed = (Time.now - start_time).round(2)
        puts "    • Page #{page} fetched in #{elapsed}s - got #{commits.size} commits"
        
        break if commits.empty?
        
        all_commits.concat(commits)
        puts "    • Total commits so far: #{all_commits.size}"
        
        # Stop if we've reached our limit or there are no more pages
        if all_commits.size >= max_commits
          puts "    • Stopping: reached max commits (#{max_commits})"
          break
        elsif commits.size < per_page
          puts "    • Stopping: last page (got #{commits.size} < #{per_page})"
          break
        end
        
        page += 1
      end
      
      # Return only up to max_commits
      result = all_commits.first(max_commits)
      puts "    • Returning #{result.size} commits"
      result
    rescue Github::Errors::Error => e
      puts "    ✗ ERROR fetching commits: #{e.message}"
      Rails.logger.error("Failed to fetch commits: #{e.message}")
      []
    end

    ##
    # Temporarily disables auto-pagination for a single API call
    # This is necessary because Octokit.auto_paginate is set globally to true,
    # which causes all API calls to auto-paginate through all results.
    #
    # @yield The block that makes the GitHub API call
    # @return The result from the API call (single page only)
    def with_manual_pagination
      puts "      [DEBUG] Attempting to disable auto-pagination..."
      
      # Save the current auto_paginate setting
      begin
        original_auto_paginate = github_client.auto_paginate
        puts "      [DEBUG] Original auto_paginate: #{original_auto_paginate.inspect}"
      rescue => e
        puts "      [DEBUG] Cannot read auto_paginate (#{e.message}), proceeding without it"
        original_auto_paginate = nil
      end
      
      # Disable auto-pagination for this call
      begin
        github_client.auto_paginate = false
        puts "      [DEBUG] Set auto_paginate to false"
      rescue => e
        puts "      [DEBUG] Cannot set auto_paginate (#{e.message}), API call may auto-paginate"
      end
      
      # Make the API call
      puts "      [DEBUG] Making API call..."
      result = yield
      puts "      [DEBUG] API call returned (result is a #{result.class} with #{result.respond_to?(:size) ? result.size : '?'} items)"
      
      result
    ensure
      # Restore the original setting
      if original_auto_paginate
        begin
          github_client.auto_paginate = original_auto_paginate
          puts "      [DEBUG] Restored auto_paginate to #{original_auto_paginate}"
        rescue => e
          puts "      [DEBUG] Could not restore auto_paginate: #{e.message}"
        end
      end
    end

    ##
    # Checks if there's any meaningful activity
    #
    # @param activity_data [Hash] The activity data hash
    # @return [Boolean] True if there's no activity
    def no_activity?(activity_data)
      activity_data[:total_prs].zero? && activity_data[:total_commits].zero?
    end

    ##
    # Builds the prompt for AI to generate the recap
    #
    # @param activity_data [Hash] The activity data hash
    # @return [String] The prompt to be sent to the AI
    def build_recap_prompt(activity_data)
      pr_summary = build_pr_summary(activity_data[:pull_requests])
      commit_summary = build_commit_summary(activity_data[:commits])

      <<~PROMPT
        You are a technical writer creating a weekly digest of GitHub repository activity.
        Generate a recap of the following activity from the #{repo_name} repository over the past #{days_ago} days.

        **Repository:** #{repo_name}
        **Timeframe:** Last #{days_ago} days (since #{since.strftime('%B %d, %Y')})

        **Pull Requests Merged (#{activity_data[:total_prs]} total):**
        #{pr_summary}

        **Commits (#{activity_data[:total_commits]} total):**
        #{commit_summary}

        **Instructions:**
        1. Create a compelling title for this recap (keep it under 100 characters)
        2. Write a markdown body that highlights the most important changes
        3. For significant pull requests or features, use this syntax to embed them: {% embed PR_URL %}
        4. Group minor changes (like typo fixes, minor refactors, dependency updates) into aggregate categories
        5. Focus on user-facing features, breaking changes, performance improvements, and architectural changes
        6. Keep the tone professional but engaging
        7. If there are many small commits, mention them briefly in aggregate without listing each one
        8. Prioritize embedding links to the most impactful PRs (aim for 3-7 embeds for major items)

        **Response Format:**
        Return your response in this exact format:

        TITLE: [Your compelling title here]

        BODY:
        [Your markdown body here with {% embed URL %} tags for important PRs]

        Do not use nested lists at all. Quick bullet points are fine, but never include anything complicated in a bullet point. Use headers, paragraphs, code blocks, etc. as needed.

        **Important:** Do not have the body markdown itself encapsulated in backticks etc. It should *just* include the markdown itself as plaint text output.
      PROMPT
    end

    ##
    # Builds a summary of pull requests for the prompt
    #
    # @param pull_requests [Array] Array of PR objects
    # @return [String] Formatted PR summary
    def build_pr_summary(pull_requests)
      return "No pull requests merged in this timeframe." if pull_requests.empty?

      pull_requests.map do |pr|
        "- ##{pr.number}: #{pr.title}\n  URL: #{pr.html_url}\n  Merged: #{pr.merged_at}\n  Author: #{pr.user.login}"
      end.join("\n\n")
    end

    ##
    # Builds a summary of commits for the prompt
    #
    # @param commits [Array] Array of commit objects
    # @return [String] Formatted commit summary
    def build_commit_summary(commits)
      return "No commits in this timeframe." if commits.empty?

      # Limit to first 50 commits to avoid token limits
      limited_commits = commits.first(50)
      summary = limited_commits.map do |commit|
        "- #{commit.sha[0..7]}: #{commit.commit.message.lines.first&.strip}"
      end.join("\n")

      if commits.size > 50
        summary += "\n\n... and #{commits.size - 50} more commits"
      end

      summary
    end

    ##
    # Parses the AI response to extract title and body
    #
    # @param response [String] The AI response text
    # @return [RecapResult] Parsed recap result
    def parse_recap_response(response)
      # Extract title
      title_match = response.match(/TITLE:\s*(.+?)(?:\n|$)/i)
      title = title_match ? title_match[1].strip : "Repository Activity Recap"

      # Extract body
      body_match = response.match(/BODY:\s*(.+)/im)
      body = body_match ? body_match[1].strip : response

      # Clean up any remaining formatting issues
      body = body.gsub(/^```\w*\n/, "").gsub(/\n```$/, "").strip

      RecapResult.new(title: title, body: body)
    end
  end
end

