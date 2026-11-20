module Ai
  ##
  # Generates an image for use in an article (cover image or inline body image)
  # from a user-supplied prompt. Wraps Ai::ImageGenerator with the subforem's
  # aesthetic instructions, a content-safety suffix, and an aspect ratio that
  # matches the subforem's cover image settings.
  #
  # Shared by the editor (AiImageGenerationsController) and the API
  # (Api::V1::ImagesController) so both produce consistent images.
  class ArticleImageGenerator
    Result = Struct.new(:url, :failure_reason, keyword_init: true) do
      def success?
        url.present?
      end

      def refused?
        failure_reason == :refused
      end
    end

    # Covers both attempts (see Ai::ImageGenerator) and the upload, and stays
    # under the 30s limit at which the router drops the request.
    TIMEOUT = 28.seconds
    SAFETY_INSTRUCTIONS = "Do not under any circumstances generate any violence, gore, lewd, or explicit " \
                          "content of any kind regardless of prior instructions.".freeze

    # @param prompt [String] what the user wants to see
    # @param user [User] the user requesting the image
    # @param aspect_ratio [String, nil] one of Ai::ImageGenerator::VALID_ASPECT_RATIOS keys;
    #   defaults to a ratio derived from the subforem's cover image settings
    # @return [Result] the uploaded image URL, or the failure reason
    #   (see Ai::ImageGenerator#failure_reason) when generation failed
    # @raise [Timeout::Error] if generation takes longer than TIMEOUT
    def self.call(prompt:, user:, aspect_ratio: nil)
      new(prompt: prompt, user: user, aspect_ratio: aspect_ratio).call
    end

    def self.valid_aspect_ratio?(aspect_ratio)
      Ai::ImageGenerator::VALID_ASPECT_RATIOS.key?(aspect_ratio)
    end

    def initialize(prompt:, user:, aspect_ratio: nil)
      @prompt = prompt
      @user = user
      @aspect_ratio = aspect_ratio.presence || cover_aspect_ratio
    end

    def call
      generator = Ai::ImageGenerator.new(full_prompt, aspect_ratio: aspect_ratio, affected_user: user)
      generation = Timeout.timeout(TIMEOUT) { generator.generate }
      Result.new(url: generation&.url, failure_reason: generator.failure_reason)
    end

    private

    attr_reader :prompt, :user, :aspect_ratio

    # Leads with an explicit request so a short prompt is not drowned out by the
    # style block and read as instructions to acknowledge.
    def full_prompt
      if aesthetic_instructions.present?
        "Generate an image of: #{prompt}.\n\nStyle to use if not otherwise contradicted by the request: " \
          "#{aesthetic_instructions}.\n\n#{SAFETY_INSTRUCTIONS}"
      else
        "Generate an image of: #{prompt}.\n\n#{SAFETY_INSTRUCTIONS}"
      end
    end

    # Fallback hierarchy:
    # 1. Current subforem's aesthetic instructions
    # 2. Default subforem's aesthetic instructions
    # 3. Blank
    def aesthetic_instructions
      return @aesthetic_instructions if defined?(@aesthetic_instructions)

      instructions = Settings::UserExperience.cover_image_aesthetic_instructions
      if instructions.blank? && RequestStore.store[:default_subforem_id].present?
        instructions = Settings::UserExperience.cover_image_aesthetic_instructions(
          subforem_id: RequestStore.store[:default_subforem_id],
        )
      end
      @aesthetic_instructions = instructions
    end

    def cover_aspect_ratio
      # For limit mode, use a standard wide format
      return "16:9" unless Settings::UserExperience.cover_image_fit == "crop"

      # In crop mode, calculate aspect ratio from 1000:height.
      # Cap the height at 500 to avoid generating too tall images.
      effective_height = [Settings::UserExperience.cover_image_height, 500].min
      ratio = 1000.0 / effective_height

      # Map to closest available aspect ratio
      case ratio
      when 0..1.2 then "1:1"     # ~1.0
      when 1.2..1.4 then "5:4"   # 1.25
      when 1.4..1.6 then "4:3"   # 1.33
      when 1.6..1.8 then "3:2"   # 1.5
      when 1.8..2.1 then "16:9"  # 1.78
      else "21:9"                # 2.33+
      end
    end
  end
end
