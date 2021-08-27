# NOTE: we are using `GithubIssue` to store issues, pull requests and comments
class GithubIssue < ApplicationRecord
  CATEGORIES = %w[issue issue_comment].freeze
  API_URL_REGEXP = %r{\Ahttps://api.github.com/repos/.*\z}
  PATH_COMMENT_REGEXP = %r{/issues/comments/}
  PATH_ISSUE_REGEXP = %r{/issues/}
  PATH_PULL_REQUEST_REGEXP = %r{/pulls/}
  PATH_REPO_REGEXP = %r{.*github.com/repos/}

  serialize :issue_serialized, Hash

  validates :category, inclusion: { in: CATEGORIES }
  validates :url, presence: true, length: { maximum: 400 }, format: API_URL_REGEXP
  validates :url, uniqueness: true

  class << self
    def find_or_fetch(url)
      find_by(url: url) || fetch(url)
    end

    private

    def fetch(url)
      retrieve_and_save_issue(url)
    rescue Github::Errors::NotFound => e
      raise e, error_message(url)
    end

    def retrieve_and_save_issue(url)
      issue = new(url: url)

      if PATH_COMMENT_REGEXP.match?(url)
        repo, issue_id = comment_repo_and_issue_id(url)
        issue.issue_serialized = Github::OauthClient.new.issue_comment(repo, issue_id).to_h
        issue.category = "issue_comment"
      else
        repo, issue_id = issue_or_pull_repo_and_issue_id(url)
        issue.issue_serialized = Github::OauthClient.new.issue(repo, issue_id).to_h
        issue.category = "issue"
      end

      # despite the counter intuitive name `.markdown` returns HTML rendered
      # from the original markdown
      issue.processed_html = Github::OauthClient.new.markdown(issue.issue_serialized[:body])

      issue.save!

      issue
    end

    def clean_url(url)
      url.gsub(PATH_REPO_REGEXP, "")
    end

    def comment_repo_and_issue_id(url)
      clean_url(url).split(PATH_COMMENT_REGEXP)
    end

    def issue_or_pull_repo_and_issue_id(url)
      splitter = if PATH_PULL_REQUEST_REGEXP.match?(url)
                   PATH_PULL_REQUEST_REGEXP
                 else
                   PATH_ISSUE_REGEXP
                 end

      clean_url(url).split(splitter)
    end

    def error_message(url)
      if PATH_COMMENT_REGEXP.match?(url)
        _, issue_id = comment_repo_and_issue_id(url)
        "Issue comment #{issue_id} not found"
      else
        _, issue_id = issue_or_pull_repo_and_issue_id(url)
        "Issue #{issue_id} not found"
      end
    end
  end
end
