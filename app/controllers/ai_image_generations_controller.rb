class AiImageGenerationsController < ApplicationController
  before_action :authenticate_user!
  before_action :limit_generations, only: [:create]
  after_action :verify_authorized

  # POST /ai_image_generations
  # Generates an AI image from a text prompt
  def create
    authorize :ai_image_generation

    prompt = params[:prompt]

    if prompt.blank?
      respond_to do |format|
        format.json do
          render json: { error: I18n.t("ai_image_generations_controller.prompt_required") },
                 status: :unprocessable_entity
        end
      end
      return
    end

    begin
      result = Ai::ArticleImageGenerator.call(prompt: prompt, user: current_user)

      if result.success?
        rate_limiter.track_limit_by_action(:ai_image_generation)
        respond_to do |format|
          format.json { render json: { url: result.url }, status: :ok }
        end
      else
        error_key = result.refused? ? "generation_refused" : "generation_failed"
        respond_to do |format|
          format.json do
            render json: { error: I18n.t("ai_image_generations_controller.#{error_key}") },
                   status: :unprocessable_entity
          end
        end
      end
    rescue Timeout::Error
      respond_to do |format|
        format.json do
          render json: { error: I18n.t("ai_image_generations_controller.timeout") },
                 status: :request_timeout
        end
      end
    rescue StandardError => e
      Rails.logger.error("AI image generation error: #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))

      respond_to do |format|
        format.json do
          render json: { error: I18n.t("ai_image_generations_controller.unexpected_error") },
                 status: :internal_server_error
        end
      end
    end
  end

  private

  def limit_generations
    rate_limit!(:ai_image_generation)
  end
end
