require "rails_helper"

describe RateLimitCheckerHelper, type: :helper do
  describe "#configurable_rate_limits" do
    it "returns a hash with the right structure" do
      helper.configurable_rate_limits.each do |key, value_hash|
        expect(key).to match(/\Arate_limit/)
        expect(value_hash.keys).to match_array(%i[min placeholder description])
      end
    end
  end
end
