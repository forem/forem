#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to close obvious spam issues in the forem/forem repository
# Usage: ruby scripts/close_spam_issues.rb [--dry-run]

require 'net/http'
require 'json'
require 'uri'

class SpamIssueCloser
  GITHUB_API_BASE = 'https://api.github.com'
  REPO_OWNER = 'forem'
  REPO_NAME = 'forem'
  
  # Conservative spam detection patterns
  SPAM_PATTERNS = {
    # Meaningless titles
    meaningless_titles: /\A(a{3,}|test|spam|\.{3,}|x{3,}|z{3,})\z/i,
    
    # Suspicious content in body
    suspicious_ip_pattern: /\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?:\.\d{1,3}){2,}\b/,
    random_chars: /@[a-z0-9]{8,}:/,
    
    # Empty or template-only content
    empty_description: /\*\*Describe the bug\*\*\s*\n\s*\n\s*\n/,
    empty_reproduction: /\*\*To Reproduce\*\*\s*\n\s*\n\s*\n/,
    empty_expected: /\*\*Expected behavior\*\*\s*\n\s*\n\s*\n/
  }.freeze
  
  def initialize(dry_run: false)
    @dry_run = dry_run
    @github_token = ENV['GITHUB_TOKEN']
    raise 'GITHUB_TOKEN environment variable is required' unless @github_token
  end
  
  def run
    puts "Starting spam issue detection (dry_run: #{@dry_run})"
    
    open_issues = fetch_open_issues
    spam_issues = detect_spam_issues(open_issues)
    
    if spam_issues.empty?
      puts "No obvious spam issues found"
      return
    end
    
    puts "Found #{spam_issues.length} obvious spam issue(s):"
    spam_issues.each do |issue|
      puts "  ##{issue['number']}: #{issue['title']}"
    end
    
    unless @dry_run
      close_spam_issues(spam_issues)
    end
  end
  
  private
  
  def fetch_open_issues
    puts "Fetching open issues..."
    
    uri = URI("#{GITHUB_API_BASE}/repos/#{REPO_OWNER}/#{REPO_NAME}/issues")
    uri.query = URI.encode_www_form({
      state: 'open',
      per_page: 100,
      labels: 'bug' # Focus on bug reports which are most likely to be spam
    })
    
    response = github_request(uri)
    JSON.parse(response.body)
  end
  
  def detect_spam_issues(issues)
    spam_issues = []
    
    issues.each do |issue|
      next if issue['pull_request'] # Skip pull requests
      
      spam_reasons = check_for_spam(issue)
      if spam_reasons.any?
        puts "Issue ##{issue['number']} detected as spam: #{spam_reasons.join(', ')}"
        spam_issues << issue
      end
    end
    
    spam_issues
  end
  
  def check_for_spam(issue)
    reasons = []
    title = issue['title'] || ''
    body = issue['body'] || ''
    
    # Check for meaningless title
    if SPAM_PATTERNS[:meaningless_titles].match?(title)
      reasons << "meaningless title"
    end
    
    # Check for suspicious IP patterns
    if SPAM_PATTERNS[:suspicious_ip_pattern].match?(body)
      reasons << "suspicious IP pattern"
    end
    
    # Check for random character patterns
    if SPAM_PATTERNS[:random_chars].match?(body)
      reasons << "random character pattern"
    end
    
    # Check if all main sections are empty (indicating template spam)
    empty_sections = 0
    empty_sections += 1 if SPAM_PATTERNS[:empty_description].match?(body)
    empty_sections += 1 if SPAM_PATTERNS[:empty_reproduction].match?(body)
    empty_sections += 1 if SPAM_PATTERNS[:empty_expected].match?(body)
    
    if empty_sections >= 3
      reasons << "empty template sections"
    end
    
    # Additional check: very short title with empty body
    if title.length <= 4 && body.strip.length < 50
      reasons << "very short title and body"
    end
    
    reasons
  end
  
  def close_spam_issues(spam_issues)
    spam_issues.each do |issue|
      close_issue(issue)
    end
  end
  
  def close_issue(issue)
    issue_number = issue['number']
    puts "Closing spam issue ##{issue_number}: #{issue['title']}"
    
    uri = URI("#{GITHUB_API_BASE}/repos/#{REPO_OWNER}/#{REPO_NAME}/issues/#{issue_number}")
    
    request_body = {
      state: 'closed',
      state_reason: 'not_planned'
    }.to_json
    
    response = github_request(uri, method: 'PATCH', body: request_body)
    
    if response.code == '200'
      puts "  ✓ Successfully closed issue ##{issue_number}"
      
      # Add a comment explaining why it was closed
      add_closing_comment(issue_number)
    else
      puts "  ✗ Failed to close issue ##{issue_number}: #{response.body}"
    end
  end
  
  def add_closing_comment(issue_number)
    uri = URI("#{GITHUB_API_BASE}/repos/#{REPO_OWNER}/#{REPO_NAME}/issues/#{issue_number}/comments")
    
    comment_body = {
      body: "This issue has been automatically closed as it appears to be spam or contains insufficient information. " \
            "If this was closed in error, please feel free to open a new issue with more detailed information."
    }.to_json
    
    response = github_request(uri, method: 'POST', body: comment_body)
    
    if response.code == '201'
      puts "  ✓ Added closing comment to issue ##{issue_number}"
    else
      puts "  ✗ Failed to add comment to issue ##{issue_number}: #{response.body}"
    end
  end
  
  def github_request(uri, method: 'GET', body: nil)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request_class = case method
                   when 'GET' then Net::HTTP::Get
                   when 'POST' then Net::HTTP::Post
                   when 'PATCH' then Net::HTTP::Patch
                   else raise "Unsupported method: #{method}"
                   end
    
    request = request_class.new(uri)
    request['Authorization'] = "token #{@github_token}"
    request['Accept'] = 'application/vnd.github.v3+json'
    request['User-Agent'] = 'forem-spam-issue-closer'
    
    if body
      request['Content-Type'] = 'application/json'
      request.body = body
    end
    
    response = http.request(request)
    
    unless response.code.start_with?('2')
      puts "GitHub API error: #{response.code} #{response.body}"
    end
    
    response
  end
end

# Main execution
if __FILE__ == $0
  dry_run = ARGV.include?('--dry-run')
  
  begin
    closer = SpamIssueCloser.new(dry_run: dry_run)
    closer.run
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end