# GitlabTag generates the following api links
# getting an issue
#   https://gitlab.com/api/v4/projects/gitlab-org/gitlab/issues/1
# getting an merge request
#   https://gitlab.com/api/v4/projects/gitlab-org/gitlab/merge_requests/1
class GitlabTag
  class GitlabIssueTag
    PARTIAL = "liquids/gitlab_issue".freeze

    def initialize(link)
      @orig_link = link
      @link = parse_link(link)
      @content = GitlabIssue.find_or_fetch(@link)
      @content_json = @content.issue_serialized
      @body = @content.processed_html.html_safe
    end

    def render
      ActionController::Base.new.render_to_string(
        partial: PARTIAL,
        locals: {
          title: @content_json['title'],
          issue_number: @content_json['id'],
          user_url: @content_json['author']['web_url'],
          user_avatar_url: @content_json['author']['avatar_url'],
          username: @content_json['author']['username'],
          date_link: @content_json['web_url'],
          date: Time.zone.parse(@content_json['created_at'].to_s).utc.strftime("%b %d, %Y"),
          body: @body
        },
      )
    end

    private

    def parse_link(link)
      link = ActionController::Base.helpers.strip_tags(link)
      clean_link = clean(link)
      if valid_link?(clean_link)
        generate_api_link(clean_link)
      else
        raise_error
      end
    end

    def generate_api_link(input)
      "https://gitlab.com/api/v4/projects/#{input.gsub(/.*gitlab\.com\//, '')}"
    end

    def clean(link)
      link = remove_params(link)
      link = remove_note(link)
      link = remove_gitlab_global_scope(link)
      link = remove_blank_char(link)
      link
    end

    def remove_blank_char(link)
      link.delete(" ")
    end

    def remove_params(link)
      link.gsub(/\?.*/, "")
    end

    def remove_note(link)
      link.gsub(/#note_\d+/, "")
    end

    # https://gitlab.com/gitlab-org/gitlab/-/blob/v12.9.2-ee/config/routes.rb#L74
    def remove_gitlab_global_scope(link)
      link.gsub("/-/", "/")
    end

    def valid_link?(link)
      link_without_domain = link.gsub(/.*gitlab\.com\//, "").split("/")
      validations = [
        /.*gitlab\.com\//.match?(link),
        link_without_domain.length == 4,
        link_without_domain[3].to_i.positive?,
      ]
      validations.all? || raise_error
    end

    def raise_error
      raise StandardError, "Invalid Gitlab issue link"
    end
  end
end
