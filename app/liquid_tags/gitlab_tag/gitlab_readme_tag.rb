class GitlabTag
  class GitlabReadmeTag
    PARTIAL = "liquids/gitlab_readme".freeze

    attr_reader :content, :options, :readme_html

    def initialize(link)
      parsed_link = parse_link(link)
      @options = parse_options(link)
      @content = Gitlab.project(parsed_link)
      @readme_html = fetch_readme if readme_url
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
      raise StandardError, "GitLab tag: `#{link}`: Invalid option - did you mean `no-readme`?" unless options.empty? || validated_options.any?

      options
    end

    def show_readme?
      options.none? "no-readme"
    end

    def readme_url
      content.readme_url
    end

    def fetch_readme
      ref, file = readme_url.split("/")[-2..-1]
      markdown_body = Gitlab.file_contents(content.id, file, ref)
      Gitlab.markdown(markdown_body).html
    end

    def sanitize_link(link)
      link = ActionController::Base.helpers.strip_tags(link)
      link.gsub(/.*gitlab\.com\//, "")
    end

    def raise_error
      raise StandardError, "Invalid Gitlab Repo link"
    end
  end
end
