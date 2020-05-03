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

    def initialize(link)
      @orig_link = link
      @link = parse_link(link)
      @content = GithubIssue.find_or_fetch(@link)
      @content_json = @content.issue_serialized
      @body = @content.processed_html.html_safe
    end

    def render
      ActionController::Base.new.render_to_string(
        partial: PARTIAL,
        locals: {
          title: @content_json[:title],
          issue_number: @content_json[:number],
          user_html_url: @content_json[:user][:html_url],
          user_avatar_url: @content_json[:user][:avatar_url],
          username: @content_json[:user][:login],
          date_link: @content_json[:html_url],
          date: Time.zone.parse(@content_json[:created_at].to_s).utc.strftime("%b %d, %Y"),
          body: @body
        },
      )
    end

    private

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
      input = input.gsub(/\?.*/, "")
      input = input.gsub(/\d{1,}#issuecomment-/, "comments/") if input.include?("#issuecomment-")
      # GitHub's public PR URLs are "/pull/{id}" but the API requires "/pulls/{id}"
      input = input.gsub(/\/pull\//, "/pulls/")
      "https://api.github.com/repos/#{input.gsub(/.*github\.com\//, '')}"
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
  end
end
