module Ai
  class CommunityCopy
    def initialize(subforem_id, brain_dump)
      @subforem_id = subforem_id
      @brain_dump = brain_dump
      @subforem = Subforem.find(subforem_id)
    end

    def write!
      generate_description
      generate_tagline
      generate_internal_content_description
    rescue StandardError => e
      Rails.logger.error("Failed to write community copy: #{e.message}") \
    end

    private

    def generate_description
      comparable_descriptions = Subforem.cached_discoverable_ids.map do |id|
        Settings::Community.community_description(subforem_id: id)
      end.compact
      prompt = "Generate a community description for the subforem with domain #{@subforem.domain} based on the following brain dump: #{@brain_dump}. Use the following examples as a reference:\n\n#{comparable_descriptions.join(', ')}"
      response = Ai::Base.new.call(prompt)
      Settings::Community.set_community_description(response, subforem_id: @subforem_id)
    rescue StandardError => e
      Rails.logger.error("Failed to generate community description: #{e.message}")
    end

    def generate_tagline
      comparable_taglines = Subforem.cached_discoverable_ids.map do |id|
        Settings::Community.tagline(subforem_id: id)
      end.compact
      prompt = "Generate a tagline for the subforem with domain #{@subforem.domain} based on the following brain dump: #{@brain_dump}. Use the following examples as a reference:\n\n#{comparable_taglines.join(', ')}"
      response = Ai::Base.new.call(prompt)
      Settings::Community.set_tagline(response, subforem_id: @subforem_id)
    rescue StandardError => e
      Rails.logger.error("Failed to generate community tagline: #{e.message}")
    end

    def generate_internal_content_description
      prompt = "Generate an internal content specification for the purpose of moderation for the subforem with domain #{@subforem.domain}. It should be a consise but relatively exhaustive instruction for what content should and shouldn't exist on the site. It should be no more than 1,500 characters long so keep it relatively concise. Base the document on the following brain dump:\n\n#{@brain_dump}"
      response = Ai::Base.new.call(prompt)
      Settings::RateLimit.set_internal_content_description_spec(response, subforem_id: @subforem_id)
    rescue StandardError => e
      Rails.logger.error("Failed to generate internal content description: #{e.message}")
    end
  end
end
