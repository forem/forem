class AiChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!

  def index
    # Render the initial chat interface
  end

  def create
    user_message = params[:message]
    history = params[:history] || []

    if user_message.blank?
      render json: { error: "Message cannot be blank" }, status: :unprocessable_entity
      return
    end

    chat_service = Ai::ChatService.new(current_user, history: history)
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

  def ensure_admin!
    return if current_user.any_admin?

    respond_to do |format|
      format.html { redirect_to root_path, alert: "You are not authorized to access this page." }
      format.json { render json: { error: "Unauthorized" }, status: :unauthorized }
    end
  end
end
