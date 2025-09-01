module Subforems
  class CreateFromScratchWorker
    include Sidekiq::Worker

    sidekiq_options queue: :default, retry: 3

    def perform(subforem_id, brain_dump, name, logo_url, bg_image_url = nil, default_locale = 'en')
      subforem = Subforem.find(subforem_id)

      # Set admin_action_taken_at at start
      Settings::General.set_admin_action_taken_at(Time.current, subforem_id: subforem.id)

      # Set the community name
      name = Settings::Community.set_community_name(name, subforem_id: subforem.id)

      # Set the default locale for this subforem
      Settings::UserExperience.set_default_locale(default_locale, subforem_id: subforem.id)

      # Generate images
      Images::GenerateSubforemImages.call(subforem.id, logo_url, bg_image_url)

      # Generate AI content with locale-specific prompts
      Ai::CommunityCopy.new(subforem.id, brain_dump, default_locale).write!
      Ai::ForemTags.new(subforem.id, brain_dump, default_locale).upsert!
      Ai::AboutPageGenerator.new(subforem.id, brain_dump, name, default_locale).generate!

      # Set admin_action_taken_at at finish
      Settings::General.set_admin_action_taken_at(Time.current, subforem_id: subforem.id)

      Rails.logger.info("Successfully created subforem #{subforem.domain} with AI services")
    rescue StandardError => e
      Rails.logger.error("Failed to create subforem #{subforem_id} with AI services: #{e.message}")
      Honeybadger.notify(e) if defined?(Honeybadger)
      raise e
    end
  end
end
