require "nokogiri"

class GithubTag
  class GithubReadmeTag
    PARTIAL = "liquids/github_readme".freeze

    attr_reader :client, :content, :options, :readme_html

    def initialize(link)
      parsed_link = parse_link(link)
      @options = parse_options(link)
      @client = Octokit::Client.new(access_token: token)
      @content = client.repository(parsed_link)
      @readme_html = fetch_readme(parsed_link)
    end

    def render
      ActionController::Base.new.render_to_string(
        partial: PARTIAL,
        locals: {
          content: content,
          show_readme: show_readme? && readme_html.present?,
          readme_html: readme_html
        },
      )
    end

    private

    def parse_link(link)
      link = sanitize_link(link)
      parsed_link = link.split(" ").first.delete(" ")
      raise_error if parsed_link.split("/").length > 2

      parsed_link
    end

    def valid_option(option)
      option.match(/no-readme/)
    end

    def parse_options(link)
      opts = sanitize_link(link)
      _, *options = opts.split(" ")

      validated_options = options.map { |option| valid_option(option) }.reject(&:nil?)
      raise StandardError, "GitHub tag: `#{link}`: Invalid option - did you mean `no-readme`?" unless options.empty? || validated_options.any?

      options
    end

    def show_readme?
      options.none? "no-readme"
    end

    def fetch_readme(link)
      readme_html = client.readme(link, accept: "application/vnd.github.html")
      readme = client.readme(link)
      clean_relative_path!(readme_html, readme.download_url)
    rescue Octokit::NotFound => _e
      nil
    end

    def sanitize_link(link)
      link = ActionController::Base.helpers.strip_tags(link)
      link.gsub(/.*github\.com\//, "")
    end

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
