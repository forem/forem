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
      final_guide_text = Ai::LiquidTagGuide.guide_text

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
