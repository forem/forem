class GithubTag
  class GithubCodeTag
    PARTIAL = "liquids/github_code".freeze

    def initialize(link)
      @original_link = get_original_link(link)
      @link = parse_link(link)
      @content = get_content(@link)
    end

    def render
      ActionController::Base.new.render_to_string(
        partial: PARTIAL,
        locals: {
          file_path: @content[:file_path],
          body: @content[:body],
          start_line: @content[:start_line],
          end_line: @content[:end_line],
          original_link: @original_link,
          ref_name: @content[:ref_name]
        },
      )
    end

    def parse_link(link)
      link = sanitize_link(link)
      link.split(" ").first.delete(" ")
    end

    def get_repo_info(link)
      repo_details = link.split("/")
      raise_error if repo_details.length < 5

      user_name = repo_details[0]
      repo_name = repo_details[1]
      ref_name = repo_details[3]

      file_link = repo_details[4..-1].join("/").split("#")

      {
        user_name: user_name,
        repo_path: "#{user_name}/#{repo_name}",
        ref_name: ref_name,
        file_link: file_link
      }
    end

    def get_file_info(file_link)
      file_path = file_link[0]
      file_type = file_path[file_path.rindex(".") + 1..-1]

      line_info = file_link[1].split("-")
      start_line = Integer(line_info[0][1..-1])
      end_line = Integer(line_info[1][1..-1])

      {
        file_path: file_path,
        file_type: file_type,
        start_line: start_line,
        end_line: end_line
      }
    end

    def get_sliced_content(file_content, file_info)
      start_line = file_info[:start_line] - 1
      end_line = file_info[:end_line] - 1
      file_content[(start_line - 1)..(end_line - 1)]
    end

    def get_content(link)
      repo_info = get_repo_info(link)
      file_info = get_file_info(repo_info[:file_link])

      client = Octokit::Client.new(access_token: token)
      file = client.contents(repo_info[:repo_path],
                             path: file_info[:file_path],
                             ref: file_info[:ref_name])

      file_content = Base64.decode64(file[:content]).split("\n")
      sliced_file_content = get_sliced_content(file_content, file_info)

      renderer = Redcarpet::Render::HTMLRouge.new

      render_opt = {
        wrap: false,
        line_numbers: true,
        start_line: file_info[:start_line]
      }

      {
        body: renderer.block_code(sliced_file_content.join("\n"),
                                  file_info[:file_type],
                                  render_opt),
        file_path: "#{repo_info[:repo_path]}/#{file_info[:file_path]}",
        ref_name: file_info[:ref_name],
        start_line: file_info[:start_line],
        end_line: file_info[:end_line]
      }
    end

    private

    def get_original_link(link)
      link = ActionController::Base.helpers.strip_tags(link)
      link.split(" ").first.delete(" ")
    end

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
