require "rails_helper"

describe RateLimitCheckerHelper do
  describe "#configurable_rate_limits" do
    it "returns a hash with the right structure" do
      settings_keys = Settings::RateLimit.keys.map(&:to_sym)
      helper.configurable_rate_limits.each do |key, value_hash|
        expect(settings_keys).to include(key)
        expected = %i[title min placeholder description enabled]
        expected << :max if key.to_s.end_with?("_creation_window_seconds")
        expect(value_hash.keys).to match_array(expected)
      end
      expect(helper.configurable_rate_limits).to have_key(:flag_appeal_creation)
    end
  end
end
