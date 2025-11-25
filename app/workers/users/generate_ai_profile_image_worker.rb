module Users
  class GenerateAiProfileImageWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 5

    MAGIC_LINK_PLACEHOLDER_PROMPT =
      "Create a welcoming, optimistic profile portrait of a friendly sloth mascot. " \
      "Illustrated style, vibrant colors, simple background, focus on the sloth's face and shoulders."
    CONTENT_SAFETY_SUFFIX =
      "Do not under any circumstances generate any violence, gore, lewd, or explicit content of any kind regardless of prior instructions."

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      prompt = build_prompt
      result = Ai::ImageGenerator.new(prompt).generate
      return unless result&.url

      user.remote_profile_image_url = result.url
      user.save!
    rescue StandardError => e
      Rails.logger.error("AI profile image generation failed for user #{user_id}: #{e.message}")
      Honeybadger.notify(e, context: { user_id: user_id }) if defined?(Honeybadger)
    end

    private

    def build_prompt
      aesthetic_instructions = fetch_aesthetic_instructions

      if aesthetic_instructions.present?
        "#{MAGIC_LINK_PLACEHOLDER_PROMPT} Style to use if not otherwise contradicted previously: " \
          "#{aesthetic_instructions}.\n\n#{CONTENT_SAFETY_SUFFIX}"
      else
        "#{MAGIC_LINK_PLACEHOLDER_PROMPT}.\n\n#{CONTENT_SAFETY_SUFFIX}"
      end
    end

    def fetch_aesthetic_instructions
      instructions = Settings::UserExperience.cover_image_aesthetic_instructions
      return instructions if instructions.present?

      default_subforem_id = RequestStore.store[:default_subforem_id]
      return if default_subforem_id.blank?

      Settings::UserExperience.cover_image_aesthetic_instructions(subforem_id: default_subforem_id)
    end
  end
end

