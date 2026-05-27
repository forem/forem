module Trends
  class GenerateCoverImageWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 5

    CONTENT_SAFETY_SUFFIX =
      "Do not under any circumstances generate any violence, gore, lewd, or explicit content of any kind regardless of prior instructions."

    def perform(trend_id)
      # Ensure API key is configured
      return unless ENV["GEMINI_API_KEY"].present?

      trend = Trend.find_by(id: trend_id)
      return unless trend
      return if trend.cover_image.present? # Only generate once

      prompt = build_prompt(trend)

      # 16:9 is the standard aspect ratio for linkedin-friendly/OG images
      result = Ai::ImageGenerator.new(
        prompt,
        aspect_ratio: "16:9"
      ).generate

      return unless result&.url

      trend.update!(cover_image: result.url)
    rescue StandardError => e
      Rails.logger.error("AI cover image generation failed for trend #{trend_id}: #{e.message}")
      Honeybadger.notify(e, context: { trend_id: trend_id }) if defined?(Honeybadger)
    end

    private

    def build_prompt(trend)
      base_prompt = "A cheeky and abstract representation of the following developer trend topic: '#{trend.name}'. Context: #{trend.description}."
      aesthetic_instructions = fetch_aesthetic_instructions

      if aesthetic_instructions.present?
        "#{base_prompt} Style to use if not otherwise contradicted previously: " \
          "#{aesthetic_instructions}.\n\n#{CONTENT_SAFETY_SUFFIX}"
      else
        "#{base_prompt}\n\n#{CONTENT_SAFETY_SUFFIX}"
      end
    end

    def fetch_aesthetic_instructions
      instructions = Settings::UserExperience.cover_image_aesthetic_instructions
      return instructions if instructions.present?

      default_subforem_id = RequestStore.store[:default_subforem_id] || Subforem.cached_default_id
      return if default_subforem_id.blank?

      Settings::UserExperience.cover_image_aesthetic_instructions(subforem_id: default_subforem_id)
    end
  end
end
