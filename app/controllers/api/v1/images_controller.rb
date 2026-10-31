module Api
  module V1
    # Uploads and AI-generates images for use in articles. The returned URL can
    # be embedded in body_markdown (e.g. `![alt](url)`) or set as an article's
    # `main_image` (cover image) via the articles API.
    #
    # Both endpoints are rate limited per user with a configurable count and
    # window (see Settings::RateLimit api_image_upload* and
    # api_ai_image_generation*). Setting a count to 0 disables that endpoint.
    class ImagesController < ApiController
      MAX_PROMPT_LENGTH = 1000

      before_action :authenticate_with_api_key!
      after_action :verify_authorized

      # POST /api/images
      def create
        authorize :image_upload, :create?

        image = params[:image]
        return error_unprocessable_entity(t_images("image_required")) unless file?(image)
        return error_unprocessable_entity(filename_too_long_message) if long_filename?(image)

        @user.rate_limiter.consume!(:api_image_upload)

        uploader = ArticleImageUploader.new
        uploader.store!(image)
        # File storage (e.g. local dev) yields a relative path; API clients need
        # an absolute URL to use in markdown or as main_image.
        render json: { url: URL.url(uploader.url) }, status: :created
      rescue CarrierWave::IntegrityError => e
        error_unprocessable_entity(e.message)
      rescue CarrierWave::ProcessingError
        error_unprocessable_entity(I18n.t("image_uploads_controller.server_error"))
      end

      # POST /api/images/generate
      def generate
        authorize :ai_image_generation, :create?

        prompt = params[:prompt].to_s.strip
        aspect_ratio = params[:aspect_ratio].presence
        error = generation_param_error(prompt, aspect_ratio)
        return error_unprocessable_entity(error) if error

        unless ::AI_AVAILABLE
          return render json: { error: t_images("generation_unavailable"), status: 503 },
                        status: :service_unavailable
        end

        # Consumed before generating: generation is expensive, so failed and
        # timed-out attempts count against the limit too.
        @user.rate_limiter.consume!(:api_ai_image_generation)

        result = Ai::ArticleImageGenerator.call(prompt: prompt, user: @user, aspect_ratio: aspect_ratio)
        if result.success?
          render json: { url: URL.url(result.url) }, status: :created
        else
          error_key = result.refused? ? "generation_refused" : "generation_failed"
          error_unprocessable_entity(I18n.t("ai_image_generations_controller.#{error_key}"))
        end
      rescue Timeout::Error
        render json: { error: I18n.t("ai_image_generations_controller.timeout"), status: 408 },
               status: :request_timeout
      end

      private

      def generation_param_error(prompt, aspect_ratio)
        return t_images("prompt_required") if prompt.blank?
        return t_images("prompt_too_long", max: MAX_PROMPT_LENGTH) if prompt.length > MAX_PROMPT_LENGTH
        return if aspect_ratio.nil? || Ai::ArticleImageGenerator.valid_aspect_ratio?(aspect_ratio)

        t_images("invalid_aspect_ratio", valid: Ai::ImageGenerator::VALID_ASPECT_RATIOS.keys.join(", "))
      end

      def t_images(key, **)
        I18n.t("api.v1.images_controller.#{key}", **)
      end
    end
  end
end
