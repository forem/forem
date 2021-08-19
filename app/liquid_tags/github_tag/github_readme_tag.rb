class GithubTag
  class GithubReadmeTag
    PARTIAL = "liquids/github_readme".freeze
    GITHUB_DOMAIN_REGEXP = %r{.*github.com/}.freeze
    OPTION_NO_README = "no-readme".freeze
    VALID_OPTIONS = [OPTION_NO_README].freeze

    def initialize(input)
      @repository_path, @options = parse_input(input)
    end

    def render
      content = Github::OauthClient.new.repository(repository_path)

      if show_readme?
        readme_html = fetch_readme(repository_path, content.html_url)
      end

      ApplicationController.render(
        partial: PARTIAL,
        locals: {
          content: content,
          show_readme: readme_html.present?,
          readme_html: readme_html
        },
      )
    rescue Github::Errors::NotFound, Github::Errors::InvalidRepository
      raise_error
    end

    private

    attr_reader :repository_path, :options, :content

    def parse_input(input)
      sanitized_input = sanitize_input(input)

      path, *options = sanitized_input.split

      validate_options!(*options)

      path.delete_suffix!("/") # remove optional trailing forward slash
      repository_path = URI.parse(path)
      repository_path.query = repository_path.fragment = nil

      [repository_path.normalize.to_s, options]
    end

    def validate_options!(*options)
      return if options.empty?
      return if options.all? { |o| VALID_OPTIONS.include?(o) }

      message = "GitHub tag: invalid options: #{options - VALID_OPTIONS} - supported options: #{VALID_OPTIONS}"
      raise StandardError, message
    end

    def show_readme?
      options.none?(OPTION_NO_README)
    end

    def fetch_readme(repository_path, repository_url)
      readme_html = Github::OauthClient.new.readme(repository_path, accept: "application/vnd.github.html")
      clean_relative_path!(readme_html, repository_url)
    rescue Github::Errors::NotFound
      nil
    end

    def sanitize_input(input)
      ActionController::Base.helpers.strip_tags(input)
        .gsub(GITHUB_DOMAIN_REGEXP, "")
        .strip
    end

    def raise_error
      raise StandardError, "Invalid GitHub repository path or URL"
    end

    def clean_relative_path!(readme_html, url)
      readme = Nokogiri::HTML(readme_html)

      readme.css("img, a").each do |element|
        attribute = element.name == "img" ? "src" : "href"

        element["href"] = "" if attribute == "href" && element.attributes[attribute].blank?
        element["src"] = "" if attribute == "src" && element.attributes[attribute].blank?

        path = element.attributes[attribute].value
        element.attributes[attribute].value = "#{url}#{path}" if path[0, 4] != "http"
      end

      readme.to_html
    end
  end
end
