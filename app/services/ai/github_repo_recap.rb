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
      activity_data = fetch_github_activity
      
      return nil if no_activity?(activity_data)

      prompt = build_recap_prompt(activity_data)
      response = @ai_client.call(prompt)
      
      parse_recap_response(response)
    rescue StandardError => e
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
      pull_requests = fetch_merged_pull_requests
      commits = fetch_recent_commits
      
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
      all_prs = github_client.pull_requests(
        repo_name,
        state: "closed",
        sort: "updated",
        direction: "desc"
      )

      # Filter for merged PRs within our timeframe
      all_prs.select do |pr|
        pr.merged_at && Time.parse(pr.merged_at.to_s) >= since
      end
    rescue Github::Errors::Error => e
      Rails.logger.error("Failed to fetch pull requests: #{e.message}")
      []
    end

    ##
    # Fetches recent commits from the repository
    #
    # @return [Array<Sawyer::Resource>] Array of commit objects
    def fetch_recent_commits
      github_client.commits(repo_name, since: since.iso8601)
    rescue Github::Errors::Error => e
      Rails.logger.error("Failed to fetch commits: #{e.message}")
      []
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

        **Important:** Do not include triple backticks or markdown code blocks in your response. Just provide the title and body as plain text/markdown.
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

