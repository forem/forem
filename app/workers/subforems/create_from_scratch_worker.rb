module Subforems
  class CreateFromScratchWorker
    include Sidekiq::Worker

    sidekiq_options queue: :default, retry: 3

    def perform(subforem_id, brain_dump, name, logo_url, bg_image_url = nil)
      subforem = Subforem.find(subforem_id)

      # Set admin_action_taken_at at start
      Settings::General.admin_action_taken_at = Time.current

      # Set the community name
      Settings::Community.set_community_name(name, subforem_id: subforem.id)

      # Generate images
      Images::GenerateSubforemImages.call(subforem.id, logo_url, bg_image_url)

      # Generate AI content
      Ai::CommunityCopy.new(subforem.id, brain_dump).write!
      Ai::ForemTags.new(subforem.id, brain_dump).upsert!
      Ai::AboutPageGenerator.new(subforem.id, brain_dump, name).generate!

      # Set admin_action_taken_at at finish
      Settings::General.admin_action_taken_at = Time.current

      Rails.logger.info("Successfully created subforem #{subforem.domain} with AI services")
    rescue StandardError => e
      Rails.logger.error("Failed to create subforem #{subforem_id} with AI services: #{e.message}")
      Honeybadger.notify(e) if defined?(Honeybadger)
      raise e
    end
  end
end
