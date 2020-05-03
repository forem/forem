# GithubTag generates the following API links:
# getting an issue
#   https://api.github.com/repos/facebook/react/issues/9218
# getting a pull request
#   https://api.github.com/repos/facebook/react/pulls/14105
# getting a comment belonging to an issue
#   https://api.github.com/repos/facebook/react/issues/comments/287635042
class GithubTag
  class GithubIssueTag
    PARTIAL = "liquids/github_issue".freeze
    API_BASE_ENDPOINT = "https://api.github.com/repos/".freeze

    def initialize(link)
      @orig_link = link
      @link = parse_link(link)
      @content = GithubIssue.find_or_fetch(@link)
      @content_json = @content.issue_serialized
      @is_issue = @content_json[:title].present?
      @created_at = @content_json[:created_at]
      @body = @content.processed_html.html_safe
    end

    def render
      ActionController::Base.new.render_to_string(
        partial: PARTIAL,
        locals: {
          body: @body,
          created_at: @created_at.rfc3339,
          date: @created_at.utc.strftime("%b %d, %Y"),
          html_url: @content_json[:html_url],
          issue_number: issue_number,
          tagline: tagline,
          title: title,
          user_avatar_url: @content_json[:user][:avatar_url],
          user_html_url: @content_json[:user][:html_url],
          username: @content_json[:user][:login],
        },
      )
    end

    private

    attr_reader :content_json

    def parse_link(link)
      link = ActionController::Base.helpers.strip_tags(link)
      link_no_space = link.delete(" ")
      if valid_link?(link_no_space)
        generate_api_link(link_no_space)
      else
        raise_error
      end
    end

    def generate_api_link(input)
      path = input.gsub(/\?.*/, "")
      path = path.gsub(/.*github\.com\//, "")

      # issue fragments are ignored in the API call
      path = path.gsub(/#issue-\d{1,}/, "") if path.include?("#issue-")

      # GitHub's public PRs URLs are "/pull/{id}" but the API requires "/pulls/{id}"
      path = path.gsub(/\/pull\//, "/pulls/") if path.include?("/pull/")

      # generated comment path if the user is trying to display a single comment
      path = path.gsub(/\d{1,}#issuecomment-/, "comments/") if path.include?("#issuecomment-")

      URI.parse(API_BASE_ENDPOINT).merge(path).to_s
    end

    def finalize_html(input)
      input.gsub(/(?!<code[^>]*?>)(@[a-zA-Z]{3,})(?![^<]*?<\/code>)/) do |target|
        "<a class=\"github-user-link\" href=\"https://github.com/#{target.delete('@')}\">#{target}</a>"
      end.html_safe
    end

    def valid_link?(link)
      link_without_domain = link.gsub(/.*github\.com\//, "").split("/")
      validations = [
        /.*github\.com\//.match?(link),
        link_without_domain.length == 4,
        link_without_domain[3].to_i.positive?,
      ]
      validations.all? || raise_error
    end

    def raise_error
      raise StandardError, "Invalid GitHub issue, pull request or comment link"
    end

    def title
      content_json[:title] || "Comment for"
    end

    def issue_number
      @issue_number ||= content_json[:number] || content_json[:issue_url].split("/").last
    end

    def tagline
      @is_issue ? "posted on" : "commented on"
    end
  end
end
