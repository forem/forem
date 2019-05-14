require "nokogiri"

class GithubTag
  class GithubReadmeTag
    PARTIAL = "liquids/github_readme".freeze

    def initialize(link)
      @link = parse_link(link)
      @content = get_content(@link)
    end

    def render
      ActionController::Base.new.render_to_string(
        partial: PARTIAL,
        locals: {
          content: @content,
          updated_html: @updated_html
        },
      )
    end

    def parse_link(link)
      link = ActionController::Base.helpers.strip_tags(link)
      link.gsub(/.*github\.com\//, "").delete(" ")
    end

    def get_content(link)
      repo_details = link.split("/")
      raise_error if repo_details.length > 2
      user_name = repo_details[0]
      repo_name = repo_details[1]
      client = Octokit::Client.new(access_token: token)
      @readme_html = client.readme user_name + "/" + repo_name, accept: "application/vnd.github.html"
      @readme = client.readme user_name + "/" + repo_name
      @updated_html = clean_relative_path!(@readme_html, @readme.download_url)
      client.repository(user_name + "/" + repo_name)
    end

    private

    def raise_error
      raise StandardError, "Invalid Github Repo link"
    end

    def clean_relative_path!(readme_html, url)
      readme = Nokogiri::HTML(readme_html)
      readme.css("img, a").each do |element|
        attribute = element.name == "img" ? "src" : "href"
        element["href"] = "" if attribute == "href" && element.attributes[attribute].blank?
        path = element.attributes[attribute].value
        element.attributes[attribute].value = url.gsub(/\/README.md/, "") + "/" + path if path[0, 4] != "http"
      end
      readme.to_html
    end

    def token
      if Rails.env.test?
        "REPLACE WITH VALID FOR VCR"
      else
        Identity.where(provider: "github").last(250).sample.token
      end
    end
  end
end
