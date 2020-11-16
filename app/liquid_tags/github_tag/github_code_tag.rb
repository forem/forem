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
          line_info: @content[:line_info],
          original_link: @original_link,
          ref_name: @content[:ref_name]
        },
      )
    end

    private

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

      file_link = repo_details[4..].join("/").split("#")

      {
        user_name: user_name,
        repo_path: "#{user_name}/#{repo_name}",
        ref_name: ref_name,
        file_link: file_link
      }
    end

    def get_file_info(file_link)
      file_path = file_link[0]
      extension_index = file_path.rindex(".")
      file_type = if extension_index.nil?
                    # use file name as type for files without extensions
                    file_path
                  else
                    file_path[extension_index + 1..]
                  end

      line_info = file_link[1].split("-")

      raise_line_number_error unless line_info[0][0] == "L"
      raise_line_number_error unless line_info.length == 1 || line_info[1][0] == "L"

      start_line = Integer(line_info[0][1..])
      end_line = if line_info.length > 1
                   Integer(line_info[1][1..])
                 end

      start_line, end_line = end_line, start_line if end_line && start_line > end_line

      {
        file_path: file_path,
        file_type: file_type,
        start_line: start_line,
        end_line: end_line
      }
    end

    def get_file_contents(repo_info, file_info)
      file = Github::OauthClient.new.contents(repo_info[:repo_path],
                                              path: file_info[:file_path],
                                              query: { ref: repo_info[:ref_name] })

      Base64.decode64(file[:content]).split("\n")
    end

    def get_sliced_content(file_content, file_info)
      start_line = file_info[:start_line] - 1
      if file_info[:end_line].nil?
        file_content[start_line..start_line]
      else
        end_line = file_info[:end_line] - 1
        file_content[start_line..end_line]
      end
    end

    def build_line_info(file_info)
      if file_info[:end_line].nil? || file_info[:start_line] == file_info[:end_line]
        "Line #{file_info[:start_line]}"
      else
        "Lines #{file_info[:start_line]} to #{file_info[:end_line]}"
      end
    end

    def get_content(link)
      repo_info = get_repo_info(link)
      file_info = get_file_info(repo_info[:file_link])
      file_content = get_file_contents(repo_info, file_info)

      raise_line_number_error if file_info[:start_line] > file_content.length

      unless file_info[:end_line].nil?
        file_info[:end_line] = [file_info[:end_line], file_content.length].min
      end

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
        line_info: build_line_info(file_info)
      }
    end

    def get_original_link(link)
      link = ActionController::Base.helpers.strip_tags(link)
      link.split(" ").first.delete(" ")
    end

    def sanitize_link(link)
      link = ActionController::Base.helpers.strip_tags(link)
      raise_error unless %r{.*github\.com/}.match?(link)
      link.gsub(%r{.*github\.com/}, "")
    end

    def raise_line_number_error
      raise StandardError, "Line number is invalid"
    end

    def raise_error
      raise StandardError, "Invalid GitHub link"
    end
  end
end
