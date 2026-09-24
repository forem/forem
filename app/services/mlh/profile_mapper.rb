module Mlh
  # Maps a MLH v4 user payload to usable Forem profile attributes.
  class ProfileMapper
    LOCATION_MAX_LENGTH = 100

    # Some fields are stored in Forem as ProfileFields rather than in Profile,
    # so we need to look them up by label. These may change depending on how
    # this Forem instance is configured.
    WORK_LABEL = "Work".freeze
    EDUCATION_LABEL = "Education".freeze
    PRONOUNS_LABEL = "Pronouns".freeze

    def self.call(...)
      new(...).call
    end

    # @param payload [Hash] a parsed /v4/users/me response
    def initialize(payload)
      @payload = payload.to_h
    end

    # @return [Hash] Usable values keyed by Profile field or ProfileField
    #   attribute name
    def call
      { "location" => location }.merge(profile_fields).compact_blank
    end

    private

    attr_reader :payload

    # Values for ProfileFields that are configured, keyed by attribute name
    def profile_fields
      values = {
        WORK_LABEL => work,
        EDUCATION_LABEL => education,
        PRONOUNS_LABEL => pronouns
      }
      ProfileField
        .where(label: values.keys)
        .pluck(:label, :attribute_name)
        .to_h { |label, attribute_name| [attribute_name, values[label]] }
    end

    def location
      address = payload["address"]
      return if address.blank?

      parts = [address["city"], address["state"], address["country_code"]].compact_blank
      parts.join(", ").truncate(LOCATION_MAX_LENGTH).presence
    end

    def work
      current_first(payload["professional_experience"])&.dig("title").presence
    end

    def education
      enrollment = current_first(payload["education"])
      return if enrollment.blank?

      [enrollment["school_name"], enrollment["major"]].compact_blank.join(", ").presence
    end

    def pronouns
      payload.dig("profile", "pronouns").presence
    end

    # MLH returns history, not a single record. Prefer whatever the user marked
    # as current, otherwise fall back to the first entry.
    def current_first(collection)
      records = Array.wrap(collection).select { |record| record.is_a?(Hash) }
      records.detect { |record| record["current"] } || records.first
    end
  end
end
