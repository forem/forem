module Ai
  class ChatService
    def initialize(user, history: [])
      @user = user
      @history = history
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
      written_data = @user.articles.published.order(created_at: :desc).limit(10).pluck(:title, :description, :path)

      viewed_ids = @user.page_views.order(created_at: :desc).limit(20).pluck(:article_id)
      viewed_data = Article.where(id: viewed_ids).pluck(:title, :description, :path)

      reading_list_ids = Reaction.readinglist_for_user(@user).order(created_at: :desc).limit(10).pluck(:reactable_id)
      reading_list_data = Article.where(id: reading_list_ids).pluck(:title, :description, :path)

      written_context = format_context(written_data)
      viewed_context = format_context(viewed_data)
      reading_list_context = format_context(reading_list_data)

      <<~PROMPT
        You are an insightful technical curator and community guide for the DEV community.
        Your goal is to provide advice and perspective to the user through the lens of their recent community activity.

        User's Recent Writing:
        #{written_context.presence || 'No recent articles written.'}

        User's Recent Viewing:
        #{viewed_context.presence || 'No recent articles viewed.'}

        User's Recently Saved to Reading List:
        #{reading_list_context.presence || 'No recent articles saved to reading list.'}

        Current Conversation History:
        #{@history.map { |m| "#{m[:role].capitalize}: #{m[:text]}" }.join("\n")}

        Guidelines:
        - Be encouraging, helpful, and technically grounded.
        - Reference their recent interests (viewed, written, or saved) if it helps provide a more personalized answer.
        - Keep responses concise and engaging.
        - Use markdown for formatting.
        - Add links to any content that is mentioned using the URLs provided in the context.
      PROMPT
    end

    def format_context(data)
      return if data.blank?

      data.map do |title, description, path|
        url = ::URL.url(path)
        "- #{title}: #{description} (Link: #{url})"
      end.join("\n")
    end
  end
end
