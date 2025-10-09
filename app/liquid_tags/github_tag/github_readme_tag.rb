class GithubTag
  class GithubReadmeTag
    PARTIAL = "liquids/github_readme".freeze
    README_REGEXP = %r{https://github\.com/[\w\-.]{1,39}/[\w\-.]{1,39}/?}
    GITHUB_DOMAIN_REGEXP = %r{.*github.com/}
    NOREADME_OPTIONS = %w[no-readme noreadme].freeze

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
      sanitized_input = input.gsub(GITHUB_DOMAIN_REGEXP, "")

      path, *options = sanitized_input.split

      validate_options!(*options)

      path.delete_suffix!("/") # remove optional trailing forward slash
      repository_path = Addressable::URI.parse(path)
      repository_path.query = repository_path.fragment = nil

      [repository_path.normalize.to_s, options]
    end

    def validate_options!(*options)
      return if options.empty?
      return if options.all? { |o| NOREADME_OPTIONS.include?(o) }

      message = I18n.t("liquid_tags.github_tag.github_readme_tag.invalid_options",
                       invalid: (options - NOREADME_OPTIONS), valid: NOREADME_OPTIONS)
      raise StandardError, message
    end

    def show_readme?
      options.none?
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
      raise StandardError, I18n.t("liquid_tags.github_tag.github_readme_tag.invalid_github_repository")
    end

    def clean_relative_path!(readme_html, url)
      readme = Nokogiri::HTML(readme_html)
      uri = URI.parse(url)
      base_github_url = "#{uri.scheme}://#{uri.host}"

      readme.css("img, a").each do |element|
        attribute = element.name == "img" ? "src" : "href"

        element["href"] = "" if attribute == "href" && element.attributes[attribute].blank?
        element["src"] = "" if attribute == "src" && element.attributes[attribute].blank?

        path = element.attributes[attribute].value
        next if path[0, 4] == "http" # Skip absolute URLs

        # Handle different types of relative paths
        if path.start_with?("/")
          # Absolute path from GitHub root (e.g., /owner/repo/blob/main/file.png)
          element.attributes[attribute].value = "#{base_github_url}#{path}"
        elsif path.start_with?("#")
          # Anchor link (e.g., #license)
          element.attributes[attribute].value = "#{url}#{path}"
        else
          # Relative path (e.g., blob/main/file.png)
          element.attributes[attribute].value = "#{url}/#{path}"
        end
      end

      readme.to_html
    end
  end
end
