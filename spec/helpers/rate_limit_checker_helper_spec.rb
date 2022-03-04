require "rails_helper"

describe RateLimitCheckerHelper, type: :helper do
  describe "#configurable_rate_limits" do
    it "returns a hash with the right structure" do
      settings_keys = Settings::RateLimit.keys.map(&:to_sym)
      helper.configurable_rate_limits.each do |key, value_hash|
        expect(settings_keys).to include(key)
        expect(value_hash.keys).to match_array(%i[title min placeholder description])
      end
    end
  end
end
