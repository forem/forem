class GitlabIssue < ApplicationRecord
  serialize :issue_serialized, Hash
  validates :category, inclusion: { in: %w[issue issue_comment] }

  def self.find_or_fetch(url)
    find_by(url: url) || fetch(url)
  end

  def merge_request?
    /\/merge_requests\/\d+\z/.match?(url)
  end

  def self.fetch(url)
    try_to_get_issue(url)
  rescue StandardError => e
    raise StandardError, "A GitLab issue 404'ed and could not be found!" if e.message.include?("404 - Not Found")

    raise StandardError, e.message
  end

  def self.try_to_get_issue(url)
    repo, issue_id = url.gsub(/.*gitlab\.com\/api\/v4\/projects\//, "").split(/\/issues\/|\/merge_requests\//)
    client = GitlabApi.new(repo)
    url.gsub!(repo, client.escaped_project)
    issue = GitlabIssue.new(url: url)

    issue.issue_serialized = get_serialized_data(client, issue, issue_id)
    issue.category = "issue"
    issue.processed_html = get_html(client, issue)
    issue.save!
    issue
  end

  def self.get_html(client, issue)
    client.markdown(issue.issue_serialized[:description]).html
  end

  def self.get_issue_serialized(client, issue_id)
    client.issue(issue_id).to_h
  end

  def self.get_merge_request_serialized(client, issue_id)
    client.merge_request(issue_id).to_h
  end

  def self.get_serialized_data(client, issue, issue_id)
    if issue.merge_request?
      get_merge_request_serialized(client, issue_id)
    else
      get_issue_serialized(client, issue_id)
    end
  end
end
