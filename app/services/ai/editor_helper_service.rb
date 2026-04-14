module Ai
  class EditorHelperService
    VERSION = "1.0"

    def initialize(user, history: [], article_state: nil)
      @user = user
      @history = history
      @article_state = article_state
      @ai_client = Ai::Base.new(wrapper: self, affected_user: user)
    end

    def generate_response(user_message)
      @history << { role: "user", text: user_message }

      response = @ai_client.call(prompt)

      @history << { role: "assistant", text: response }
      { response: response, history: @history }
    end

    private

    def prompt
      final_guide_text = Rails.cache.fetch("ai:editor_helper:guide_with_mechanics_v2", expires_in: 12.hours) do
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

        platform_mechanics = <<~MECHANICS
          Platform Mechanics Overview:
          - Tags: Tags are the primary organizational mechanism on the platform. Adding relevant tags enables the engine to correctly route the post to users following those specific subjects via their chronological or curated feed algorithms. The limit is four tags per post.
          - Titles & Markdown: Catchy, plain-language titles historically perform better. The platform engine relies strictly on standard Markdown semantics alongside special Liquid embed blocks. Avoiding extremely dense text blocks while leveraging Markdown headers actively assists readability logic.
          - Feed Personalization: Forem utilizes a heavily personalized algorithm where interactions (reads, reactions) actively shape future feed displays. Pushing engaging content inherently improves the likelihood of circulating upward in audience feeds.
          - Organizations: Users can establish or join Organizations which act as unified brands. An author can elect to publish an article under their Organization domain, aggregating followers implicitly toward the organizational brand rather than solely the personal account.
          - Following Accounts: The Follow mechanic serves to anchor a baseline connection. When users publish content, their followers are dramatically more likely to be exposed to it initially on their dashboard, establishing a core audience burst. Activity distributions heavily favor connected follow graphs.
        MECHANICS

        <<~GUIDE
          #{platform_mechanics}

          Here is the official #{Settings::Community.community_name} Editor Guide for your reference:
          #{clean_guide}

          Supported URL Embeds:
          #{clean_url_embeds}

          Supported Non-URL (Block) Embeds:
          #{clean_nonurl_embeds}
        GUIDE
      end

      internal_spec = Settings::RateLimit.internal_content_description_spec
      expanded_spec = Settings::RateLimit.expanded_content_advisement_spec

      advisement_context = ""
      if internal_spec.present? || expanded_spec.present?
        advisement_context = <<~ADVISEMENT
          The platform explicitly specifies the following about ideal content:
          #{internal_spec}
          #{expanded_spec}

        ADVISEMENT
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
        You are an insightful technical editor assistant for the #{Settings::Community.community_name} community.
        Your goal is to help the user format, write, and structure their article.

        #{final_guide_text}

        #{advisement_context}#{article_context}Current Conversation History:
        #{@history.map { |m| "#{m[:role].capitalize}: #{m[:text]}" }.join("\n")}

        Guidelines:
        - Be encouraging, helpful, and technically grounded.
        - NEVER give unsolicited advice on what subjects to write about or how to structure the story itself UNLESS the user explicitly asks for feedback on their content strategy, or their writing is overwhelmingly non-sensical.
        - Answer formatting and structural queries natively based on the official guidelines.
        - Use markdown for formatting your own responses. Provide code blocks when giving markdown examples or Liquid tags.
        - Prefer global embeds as instructions (i.e. {% embed https://github... %}) over platform-specific tags (like {% github ... %}), if possible in the context.
        - Do not assume you understand how embeds work beyond instructions as given.
        - Use the Current Article State to inform your response ONLY if it is relevant to the user's question.
      PROMPT
    end
  end
end
