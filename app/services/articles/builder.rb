module Articles
  class Builder
    attr_reader :user_id, :user_name

    def initialize(user_id, user_name, tag, prefill)
      @user_id = user_id
      @user_name = user_name
      @tag = tag
      @prefill = prefill
    end

    def tag_user_editor_v2
      submission_template = @tag.submission_template_customized(user_name).to_s

      Article.new(
        body_markdown: submission_template.split("---").last.to_s.strip,
        cached_tag_list: @tag.name,
        processed_html: "",
        user_id: user_id,
        title: submission_template.split("title:")[1].to_s.split("\n")[0].to_s.strip,
      )
    end

    def tag_user
      Article.new(
        body_markdown: @tag.submission_template_customized(user_name),
        processed_html: "",
        user_id: user_id,
      )
    end

    def prefill_user_editor_v2
      Article.new(
        body_markdown: @prefill.split("---").last.to_s.strip,
        cached_tag_list: @prefill.split("tags:")[1].to_s.split("\n")[0].to_s.strip,
        processed_html: "",
        user_id: user_id,
        title: @prefill.split("title:")[1].to_s.split("\n")[0].to_s.strip,
      )
    end

    def prefill_user
      Article.new(
        body_markdown: @prefill,
        processed_html: "",
        user_id: user_id,
      )
    end

    def tag
      Article.new(
        body_markdown: "---\ntitle: \npublished: false\ndescription: \ntags: #{@tag.name}\n---\n\n",
        processed_html: "",
        user_id: user_id,
      )
    end

    def user_editor_v2
      Article.new(user_id: user_id)
    end

    def user_editor_v1
      Article.new(
        body_markdown: "---\ntitle: \npublished: false\ndescription: \ntags: \n---\n\n",
        processed_html: "",
        user_id: user_id,
      )
    end
  end
end
