class GitlabIssue < ApplicationRecord
  serialize :issue_serialized, Hash
  validates :category, inclusion: { in: %w[issue] }

  def self.find_or_fetch(url)
    url = encode_url(url)
    find_by(url: url) || fetch(url)
  end

  def merge_request?
    /\/merge_requests\/\d+\z/.match?(url)
  end

  def self.fetch(url)
    try_to_get_issue(url)
  rescue StandardError => e
    raise StandardError, "A GitLab issue 404'ed and could not be found!" if e.message.include?("Not Found")

    raise StandardError, e.message
  end

  def self.try_to_get_issue(url)
    issue = GitlabIssue.new(url: url)
    issue.issue_serialized = issue.get_serialized_data
    issue.category = "issue"
    issue.processed_html = issue.get_html
    issue.save!
    issue
  end

  def self.extract_ids(link)
    link.gsub(/.*gitlab\.com\/api\/v4\/projects\//, "").split(/\/issues\/|\/merge_requests\//)
  end

  def self.encode_url(link)
    repo = extract_ids(link).first
    project_id = Gitlab.url_encode(repo)
    link.gsub(repo, project_id)
  end

  def get_serialized_data
    (merge_request? ? get_merge_request_serialized : get_issue_serialized).to_h
  end

  def get_html
    Gitlab.markdown(issue_serialized['description']).html
  end

  private

  def project_id
    @project_id = extract_ids.first
  end

  def unescaped_project_id
    CGI.unescape(project_id)
  end

  def resource_id
    @resource_id = extract_ids.last
  end

  def extract_ids
    @extract_ids ||= GitlabIssue.extract_ids(url)
  end

  def get_issue_serialized
    Gitlab.issue(unescaped_project_id, resource_id)
  end

  def get_merge_request_serialized
    Gitlab.merge_request(unescaped_project_id, resource_id)
  end
end
