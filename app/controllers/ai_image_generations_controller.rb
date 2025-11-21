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

    # Get aesthetic instructions with fallback hierarchy:
    # 1. Current subforem's aesthetic instructions
    # 2. Default subforem's aesthetic instructions  
    # 3. Blank
    aesthetic_instructions = Settings::UserExperience.cover_image_aesthetic_instructions
    
    if aesthetic_instructions.blank? && RequestStore.store[:default_subforem_id].present?
      aesthetic_instructions = Settings::UserExperience.cover_image_aesthetic_instructions(
        subforem_id: RequestStore.store[:default_subforem_id]
      )
    end
    
    # Combine user prompt with aesthetic instructions if they exist
    full_prompt = if aesthetic_instructions.present?
                    "#{prompt}. Style to use if not otherwise contradicted previously: #{aesthetic_instructions}.\n\nDo not under any circumstances generate any violence, gore, lewd, or explicit content of any kind regardless of prior instructions."
                  else
                    "#{prompt}.\n\nDo not under any circumstances generate any violence, gore, lewd, or explicit content of any kind regardless of prior instructions."
                  end

    # Calculate aspect ratio based on subforem cover image settings
    aspect_ratio = calculate_aspect_ratio

    begin
      # Set a reasonable timeout for the generation process
      result = Timeout.timeout(30) do
        generator = Ai::ImageGenerator.new(
          full_prompt,
          aspect_ratio: aspect_ratio
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

  def calculate_aspect_ratio
    # Get the subforem's cover image settings
    cover_image_height = Settings::UserExperience.cover_image_height
    cover_image_fit = Settings::UserExperience.cover_image_fit
    
    # If using crop mode, calculate aspect ratio from 1000:height
    # Cap the height at 500 to avoid generating too tall images
    if cover_image_fit == "crop"
      effective_height = [cover_image_height, 500].min
      width = 1000
      
      # Find the closest standard aspect ratio
      ratio = width.to_f / effective_height
      
      # Map to closest available aspect ratio
      case ratio
      when 0..1.2 then "1:1"     # ~1.0
      when 1.2..1.4 then "5:4"   # 1.25
      when 1.4..1.6 then "4:3"   # 1.33
      when 1.6..1.8 then "3:2"   # 1.5
      when 1.8..2.1 then "16:9"  # 1.78
      else "21:9"                # 2.33+
      end
    else
      # For limit mode, use a standard wide format
      "16:9"
    end
  end
end

