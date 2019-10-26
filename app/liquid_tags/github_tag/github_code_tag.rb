class GithubTag
  class GithubCodeTag
    PARTIAL = "liquids/github_code".freeze

    def initialize(link)
      @link = parse_link(link)
      @content = get_content(@link)
    end

    def render
      ActionController::Base.new.render_to_string(
        partial: PARTIAL,
        locals: {
          content: @content
        },
      )
    end

    def parse_link(link)
      link = sanitize_link(link)
      link.split(" ").first.delete(" ")
    end

    def get_content(link)
      repo_details = link.split("/")
      raise_error if repo_details.length < 5

      user_name = repo_details[0]
      repo_name = repo_details[1]
      ref_name = repo_details[3]

      file_info = repo_details[4..-1].join("/").split("#")
      file_path = file_info[0]
      file_type = file_path[file_path.rindex(".") + 1..-1]

      client = Octokit::Client.new(access_token: token)
      file = client.contents("#{user_name}/#{repo_name}",
                             path: file_path,
                             ref: ref_name)

      file_content = Base64.decode64(file[:content]).split("\n")

      line_info = file_info[1].split("-")
      start_line = Integer(line_info[0][1..-1])
      end_line = Integer(line_info[1][1..-1])

      sliced_file_content = file_content[(start_line - 1)..(end_line - 1)]

      renderer = Redcarpet::Render::HTMLRouge.new
      renderer.block_code(sliced_file_content.join("\n"), file_type, true, start_line)
    end

    private

    def sanitize_link(link)
      link = ActionController::Base.helpers.strip_tags(link)
      link.gsub(/.*github\.com\//, "")
    end

    def raise_error
      raise StandardError, "Invalid Github Code link"
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
