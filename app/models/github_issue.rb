class GithubIssue < ApplicationRecord
  serialize :issue_serialized, Hash
  validates :category, inclusion: { in: %w[issue issue_comment] }

  def self.find_or_fetch(url)
    find_by(url: url) || fetch(url)
  end

  def self.fetch(url)
    try_to_get_issue(url)
  rescue StandardError => e
    raise StandardError, "A GitHub issue 404'ed and could not be found!" if e.message.include?("404 - Not Found")

    raise StandardError, e.message
  end

  def self.try_to_get_issue(url)
    client = Octokit::Client.new(access_token: random_token)
    issue = GithubIssue.new(url: url)
    if /\/issues\/comments/.match?(url)
      repo, issue_id = url.gsub(/.*github\.com\/repos\//, "").split("/issues/comments/")
      issue.issue_serialized = client.issue_comment(repo, issue_id).to_hash
      issue.category = "issue_comment"
    else
      repo, issue_id = url.gsub(/.*github\.com\/repos\//, "").split(issue_or_pull(url))
      issue.issue_serialized = get_issue_serialized(client, repo, issue_id)
      issue.category = "issue"
    end
    issue.processed_html = get_html(client, issue)
    issue.save!
    issue
  end

  def self.get_html(client, issue)
    client.markdown(issue.issue_serialized[:body])
  end

  def self.get_issue_serialized(client, repo, issue_id)
    client.issue(repo, issue_id).to_hash
  end

  def self.random_token
    if Rails.env.test?
      "ddsddsdsdssdsds"
    else
      random_identity.token
    end
  end

  def self.random_identity
    if Rails.env.production?
      Identity.where(provider: "github").last(250).sample
    else
      Identity.where(provider: "github").last
    end
  end

  def self.issue_or_pull(url)
    if !url.include?("pull")
      "/issues/"
    else
      "/pull/"
    end
  end
end
