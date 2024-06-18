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
        .order("hotness_score DESC")
        .limit(MAX)
    end

    private

    def suggested_tags
      @suggested_tags ||= Tag.suggested_for_onboarding.order("hotness_score DESC")
    end

    def suggested_for_onboarding_or_supported
      builder = Tag.arel_table
      supported = builder[:supported].eq(true)
      suggested = builder[:suggested].eq(true)
      suggested.or(supported)
    end
  end
end
