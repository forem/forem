# frozen_string_literal: true

# Service to detect and close obvious spam issues in GitHub repositories
module SpamIssues
  class CloseObviousSpam
    # Conservative patterns to identify obvious spam
    OBVIOUS_SPAM_PATTERNS = {
      # Meaningless single-word titles
      meaningless_title: /\A(a{3,}|test|spam|\.{3,}|x{3,}|z{3,}|hello|hi{3,})\z/i,
      
      # Suspicious content patterns
      suspicious_ip: /\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?:\.\d{1,3}){2,}\b/,
      random_email_pattern: /@[a-z0-9]{8,}:/,
      
      # Template abuse - all main sections empty
      all_empty_sections: /\*\*Describe the bug\*\*\s*\n\s*\n\s*\*\*To Reproduce\*\*\s*\n\s*\n\s*\*\*Expected behavior\*\*\s*\n\s*\n/m
    }.freeze
    
    def self.call(dry_run: true)
      new(dry_run: dry_run).call
    end
    
    def initialize(dry_run: true)
      @dry_run = dry_run
    end
    
    def call
      Rails.logger.info "Starting obvious spam issue detection (dry_run: #{@dry_run})"
      
      spam_issues = detect_obvious_spam_issues
      
      if spam_issues.empty?
        Rails.logger.info "No obvious spam issues found"
        return { closed: 0, issues: [] }
      end
      
      Rails.logger.info "Found #{spam_issues.length} obvious spam issue(s)"
      
      if @dry_run
        log_spam_issues(spam_issues)
        return { closed: 0, issues: spam_issues.map { |issue| format_issue_info(issue) } }
      else
        closed_count = close_spam_issues(spam_issues)
        return { closed: closed_count, issues: spam_issues.map { |issue| format_issue_info(issue) } }
      end
    end
    
    private
    
    def detect_obvious_spam_issues
      spam_issues = []
      
      # Use GitHub API to fetch recent open issues
      client = github_client
      return [] unless client
      
      begin
        # Focus on bug-labeled issues from the last 30 days
        issues = client.list_issues(
          "forem/forem",
          state: "open",
          labels: "bug",
          since: 30.days.ago.iso8601
        )
        
        issues.each do |issue|
          next if issue.pull_request.present? # Skip pull requests
          
          if obviously_spam?(issue)
            spam_issues << issue
          end
        end
        
      rescue Github::Errors::Error => e
        Rails.logger.error "Failed to fetch issues: #{e.message}"
        return []
      end
      
      spam_issues
    end
    
    def obviously_spam?(issue)
      title = issue.title.to_s.strip
      body = issue.body.to_s.strip
      
      # Very conservative checks - only flag extremely obvious spam
      
      # Check 1: Meaningless title with empty or near-empty body
      if OBVIOUS_SPAM_PATTERNS[:meaningless_title].match?(title) && body.length < 100
        Rails.logger.info "Issue ##{issue.number} flagged: meaningless title with short body"
        return true
      end
      
      # Check 2: Suspicious IP patterns that look like spam injection
      if OBVIOUS_SPAM_PATTERNS[:suspicious_ip].match?(body)
        Rails.logger.info "Issue ##{issue.number} flagged: suspicious IP pattern"
        return true
      end
      
      # Check 3: Random character patterns that suggest automated spam
      if OBVIOUS_SPAM_PATTERNS[:random_email_pattern].match?(body)
        Rails.logger.info "Issue ##{issue.number} flagged: random character pattern"
        return true
      end
      
      # Check 4: Complete template with all sections empty
      if OBVIOUS_SPAM_PATTERNS[:all_empty_sections].match?(body) && title.length <= 10
        Rails.logger.info "Issue ##{issue.number} flagged: empty template with short title"
        return true
      end
      
      false
    end
    
    def close_spam_issues(spam_issues)
      closed_count = 0
      client = github_client
      return 0 unless client
      
      spam_issues.each do |issue|
        begin
          # Close the issue
          client.close_issue("forem/forem", issue.number)
          
          # Add explanatory comment
          client.add_comment(
            "forem/forem",
            issue.number,
            "This issue has been automatically closed as it appears to be spam or contains insufficient information to be actionable. " \
            "If this was closed in error, please feel free to open a new issue with more detailed information about the bug you're experiencing."
          )
          
          Rails.logger.info "Closed spam issue ##{issue.number}: #{issue.title}"
          closed_count += 1
          
          # Small delay to avoid rate limiting
          sleep(1)
          
        rescue Github::Errors::Error => e
          Rails.logger.error "Failed to close issue ##{issue.number}: #{e.message}"
        end
      end
      
      closed_count
    end
    
    def log_spam_issues(spam_issues)
      spam_issues.each do |issue|
        Rails.logger.info "Would close spam issue ##{issue.number}: #{issue.title}"
      end
    end
    
    def format_issue_info(issue)
      {
        number: issue.number,
        title: issue.title,
        author: issue.user.login,
        created_at: issue.created_at,
        url: issue.html_url
      }
    end
    
    def github_client
      @github_client ||= begin
        Github::OauthClient.new
      rescue => e
        Rails.logger.error "Failed to initialize GitHub client: #{e.message}"
        nil
      end
    end
  end
end