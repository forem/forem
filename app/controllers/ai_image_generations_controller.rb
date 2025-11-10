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
      # Set a reasonable timeout for the generation process
      result = Timeout.timeout(30) do
        generator = Ai::ImageGenerator.new(
          prompt,
          aspect_ratio: params[:aspect_ratio] || "16:9"
        )

        generator.generate
      end

      if result&.url
        rate_limiter.track_limit_by_action(:ai_image_generation)
        respond_to do |format|
          format.json { render json: { url: result.url }, status: :ok }
        end
      else
        respond_to do |format|
          format.json do
            render json: { error: I18n.t("ai_image_generations_controller.generation_failed") },
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

