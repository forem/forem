module Articles
  class Builder
    LINE_BREAK = "\n".freeze

    def initialize(user, tag, prefill)
      @user = user
      @tag = tag
      @prefill = prefill
    end

    def build
      if @tag.present? && @user&.editor_version == "v2"

        [tag_user_editor_v2, needs_authorization]
      elsif @tag&.submission_template.present? && @user

        [tag_user, needs_authorization]
      elsif @prefill.present? && @user&.editor_version == "v2"

        [prefill_user_editor_v2, needs_authorization]
      elsif @prefill.present? && @user

        [prefill_user, needs_authorization]
      elsif @tag.present?

        [tag, does_not_need_authorization]
      else
        return [user_editor_v2, does_not_need_authorization] if @user&.editor_version == "v2"

        [user_editor_v1, does_not_need_authorization]
      end
    end

    def needs_authorization
      true
    end

    def does_not_need_authorization
      false
    end

    def tag_user_editor_v2
      submission_template = @tag.submission_template_customized(@user.name).to_s

      Article.new(
        body_markdown: submission_template.split("---").last.to_s.strip,
        cached_tag_list: @tag.name,
        processed_html: "",
        user_id: @user.id,
        title: normalized_text(submission_template, "title:"),
      )
    end

    def tag_user
      Article.new(
        body_markdown: @tag.submission_template_customized(@user.name),
        processed_html: "",
        user_id: @user.id,
      )
    end

    def prefill_user_editor_v2
      Article.new(
        body_markdown: @prefill.split("---").last.to_s.strip,
        cached_tag_list: normalized_text(@prefill, "tags:"),
        processed_html: "",
        user_id: @user.id,
        title: normalized_text(@prefill, "title:"),
      )
    end

    def prefill_user
      Article.new(
        body_markdown: @prefill,
        processed_html: "",
        user_id: @user.id,
      )
    end

    def tag
      Article.new(
        body_markdown: "---\ntitle: \npublished: false\ndescription: \ntags: #{@tag.name}\n---\n\n",
        processed_html: "",
        user_id: @user&.id,
      )
    end

    def user_editor_v2
      Article.new(user_id: @user.id)
    end

    def user_editor_v1
      Article.new(
        body_markdown: "---\ntitle: \npublished: false\ndescription: \ntags: \n---\n\n",
        processed_html: "",
        user_id: @user&.id,
      )
    end

    def normalized_text(source, split_pattern)
      text = source.split(split_pattern)[1].to_s
      text.split(LINE_BREAK)[0].to_s.strip
    end
  end
end
