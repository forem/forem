module Tags
  class SuggestedForOnboarding
    MAX = 45

    def self.call(...)
      new(...).call
    end

    def initialize(...); end

    def call
      return suggested_tags if suggested_tags.count >= MAX

      Tag
        .where(suggested_for_onboarding_or_supported)
        .order("suggested DESC, supported DESC, taggings_count DESC, name ASC")
        .limit(MAX)
    end

    private

    def suggested_tags
      @suggested_tags ||= Tag.suggested_for_onboarding
    end

    def suggested_for_onboarding_or_supported
      builder = Tag.arel_table
      supported = builder[:supported].eq(true)
      suggested = builder[:suggested].eq(true)
      suggested.or(supported)
    end
  end
end
