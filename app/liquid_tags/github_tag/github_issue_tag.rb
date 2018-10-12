# GithubTag generates the following api links
# getting an issue
#   https://api.github.com/repos/facebook/react/issues/9218
# getting comments of an issue
#   https://api.github.com/repos/facebook/react/issues/9218/comments
# getting exat comment of an issue
#   https://api.github.com/repos/facebook/react/issues/comments/287635042
class GithubTag
  class GithubIssueTag
    def initialize(link)
      @orig_link = link
      @link = parse_link(link)
      @content = GithubIssue.find_or_fetch(@link)
    end

    def render
      content_json = @content.issue_serialized
      body = @content.processed_html
      username = content_json[:user][:login]
      user_html_url = content_json[:user][:html_url]
      user_avatar_url = content_json[:user][:avatar_url]
      date = Time.zone.parse(content_json[:created_at].to_s).utc.strftime("%b %d, %Y")
      date_link = content_json[:html_url]
      title = generate_title
      html = "" \
      "<div class=\"ltag_github-liquid-tag\"> "\
        "#{title}" \
        "<div class=\"github-thread\"> " \
          "<div class=\"timeline-comment-header\"> " \
            "<a href=\"#{user_html_url}\"> " \
              "<img class=\"github-liquid-tag-img\" src=\"#{user_avatar_url}\" alt=\"#{username} avatar\"> " \
            "</a> " \
            "<span class=\"arrow-left-outer\"></span> " \
            "<span class=\"arrow-left-inner\"></span> " \
            "<div class=\"timeline-comment-header-text\"> " \
              "<strong> " \
                "<a href=\"#{user_html_url}\">#{username}</a> " \
              "</strong> commented on <a href=\"#{date_link}\">#{date}</a> <span class=\"timestamp\"></span> " \
            "</div> " \
          "</div> " \
          "<div class=\"ltag-github-body\"> " \
            "#{body.chomp} " \
          "</div> " \
          "<div class=\"gh-btn-container\"><a class=\"gh-btn\" href=\"#{date_link}\">View on GitHub</a></div>"\
        "</div> " \
      "</div>"

      finalize_html(html)
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
      if input.include?("#issuecomment-")
        input = input.gsub(/\d{1,}#issuecomment-/, "comments/")
      end
      "https://api.github.com/repos/#{input.gsub(/.*github\.com\//, '')}"
    end

    def generate_title
      content_json = @content.issue_serialized
      title = content_json[:title]
      number = content_json[:number]
      link = content_json[:html_url]
      return unless title
      "<h1> " \
        "<a href=\"#{link}\">" \
          "<img class=\"github-logo\" src=\"#{ActionController::Base.helpers.asset_path('github-logo.svg')}\" /><span class=\"issue-title\">#{title}</span> <span class=\"issue-number\">##{number}</span> " \
        "</a>" \
      "</h1> "
    end

    def finalize_html(input)
      input.gsub(/(?!<code[^>]*?>)(@[a-zA-Z]{3,})(?![^<]*?<\/code>)/) do |target|
        "<a class=\"github-user-link\" href=\"https://github.com/#{target.delete('@')}\">#{target}</a>"
      end.html_safe
    end

    def valid_link?(link)
      link_without_domain = link.gsub(/.*github\.com\//, "").split("/")
      raise_error unless [
        !!(link =~ /.*github\.com\//),
        link_without_domain.length == 4,
        link_without_domain[3].to_i.positive?,
      ].all? { |bool| bool == true }
      true
    end

    def raise_error
      raise StandardError, "Invalid Github issue link"
    end
  end
end
