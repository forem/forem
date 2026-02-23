module Ai
  class EditorHelperService
    def initialize(user, history: [], article_state: nil)
      @user = user
      @history = history
      @article_state = article_state
      @ai_client = Ai::Base.new
    end

    def generate_response(user_message)
      @history << { role: "user", text: user_message }

      response = @ai_client.call(prompt)

      @history << { role: "assistant", text: response }
      { response: response, history: @history }
    end

    private

    def prompt
      final_guide_text = Rails.cache.fetch("ai:editor_helper:guide", expires_in: 12.hours) do
        guide_path = Rails.root.join("app/views/pages/_editor_guide_text.en.html.erb")
        url_embeds_path = Rails.root.join("app/views/pages/_supported_url_embeds_list.en.html.erb")
        nonurl_embeds_path = Rails.root.join("app/views/pages/_supported_nonurl_embeds_list.en.html.erb")

        raw_guide = File.read(guide_path)
        raw_url_embeds = File.read(url_embeds_path)
        raw_nonurl_embeds = File.read(nonurl_embeds_path)

        # Strip out ERB tags from the main guide
        content_without_erb = raw_guide.gsub(/<%=.*?%>/, "").gsub(/<%.*?%>/, "")
        clean_guide = ActionView::Base.full_sanitizer.sanitize(content_without_erb).gsub(/\s+/, " ").strip

        # Preserve layout of the Markdown Embed lists
        clean_url_embeds = raw_url_embeds.gsub(/<%=.*?%>/, "").gsub(/<%.*?%>/, "")
          .gsub(/<ul[^>]*>/, "\n")
          .gsub("</ul>", "\n")
          .gsub(/<li[^>]*>/, "- ")
          .gsub("</li>", "\n")
          .gsub(/<h4[^>]*>/, "\n### ")
          .gsub("</h4>", "\n")
          .gsub(/<p[^>]*>/, "\n")
          .gsub("</p>", "\n")
          .gsub(%r{<br\s*/?>}, "\n")
          .gsub(/<[^>]+>/, "")
          .gsub(/\n\s*\n\s*\n+/, "\n\n").strip

        clean_nonurl_embeds = raw_nonurl_embeds.gsub(/<%=.*?%>/, "").gsub(/<%.*?%>/, "")
          .gsub(/<h4[^>]*>/, "\n### ")
          .gsub("</h4>", "\n")
          .gsub(/<p[^>]*>/, "\n")
          .gsub("</p>", "\n")
          .gsub(%r{<br\s*/?>}, "\n")
          .gsub(/<pre[^>]*>/, "\n```\n")
          .gsub("</pre>", "\n```\n")
          .gsub(/<code[^>]*>/, "`")
          .gsub("</code>", "`")
          .gsub(/<[^>]+>/, "")
          .gsub(/\n\s*\n\s*\n+/, "\n\n").strip

        <<~GUIDE
          #{clean_guide}

          Supported URL Embeds:
          #{clean_url_embeds}

          Supported Non-URL (Block) Embeds:
          #{clean_nonurl_embeds}
        GUIDE
      end

      article_context = ""
      if @article_state.present?
        article_context = <<~CONTEXT
          Current Article State:
          Title: #{@article_state[:title]}
          Body:
          #{@article_state[:body]}

        CONTEXT
      end

      <<~PROMPT
        You are an insightful technical editor assistant for the DEV community.
        Your goal is to help the user format, write, and structure their article using the DEV editor.

        Here is the official DEV Editor Guide for your reference:
        #{final_guide_text}

        #{article_context}Current Conversation History:
        #{@history.map { |m| "#{m[:role].capitalize}: #{m[:text]}" }.join("\n")}

        Guidelines:
        - Be encouraging, helpful, and technically grounded.
        - Only answer questions related to using the editor, writing articles, formatting markdown, or embedding content.
        - Prefer concise answers as far as possible. Brevity is great.
        - Use markdown for formatting your own responses. Provide code blocks when giving markdown examples or Liquid tags.
        - Prefer global embeds as instructions (i.e. {% embed https://github... %}) over platform-specific tags (like {% github ... %}), if possible in the context.
        - Do not assume you understand how embeds work beyond instructions as given.
        - Use the Current Article State to inform your response ONLY if it is relevant to the user's question.
      PROMPT
    end
  end
end
