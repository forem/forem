class AiChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_ai_available!

  def index
    # Render the initial chat interface
  end

  def create
    user_message = params[:message]
    history = params[:history] || []
    context = params[:chat_context]

    if user_message.blank?
      render json: { error: "Message cannot be blank" }, status: :unprocessable_entity
      return
    end

    chat_service = if context == "editor"
                     Ai::EditorHelperService.new(current_user, history: history, article_state: params[:article_state])
                   else
                     Ai::ChatService.new(current_user, history: history)
                   end

    result = chat_service.generate_response(user_message)
    response_markdown = result[:response]

    rendered_html = MarkdownProcessor::Parser.new(response_markdown, user: current_user).evaluate_markdown

    render json: {
      message: rendered_html,
      history: result[:history]
    }
  rescue StandardError => e
    Rails.logger.error("AI Chat Error: #{e.message}")
    render json: { error: "Something went wrong. Please try again." }, status: :internal_server_error
  end

  private

  def ensure_ai_available!
    return if ::AI_AVAILABLE

    respond_to do |format|
      format.html { redirect_to root_path, alert: "AI Chat is not available." }
      format.json { render json: { error: "AI Chat feature not enabled." }, status: :forbidden }
    end
  end
end
