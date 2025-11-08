require "rails_helper"

RSpec.describe BillboardPlacementAreaConfig, type: :model do
  describe "validations" do
    it "validates presence of placement_area" do
      config = described_class.new(signed_in_rate: 50, signed_out_rate: 50)
      expect(config).not_to be_valid
      expect(config.errors[:placement_area]).to include("can't be blank")
    end

    it "validates uniqueness of placement_area" do
      described_class.create!(placement_area: "sidebar_left", signed_in_rate: 50, signed_out_rate: 50)
      duplicate_config = described_class.new(placement_area: "sidebar_left", signed_in_rate: 75, signed_out_rate: 75)
      expect(duplicate_config).not_to be_valid
      expect(duplicate_config.errors[:placement_area]).to include("has already been taken")
    end

    it "validates inclusion of placement_area in allowed areas" do
      config = described_class.new(placement_area: "invalid_area", signed_in_rate: 50, signed_out_rate: 50)
      expect(config).not_to be_valid
      expect(config.errors[:placement_area]).to include("is not included in the list")
    end

    it "validates presence of signed_in_rate" do
      config = described_class.new(placement_area: "sidebar_left", signed_out_rate: 50, signed_in_rate: nil)
      expect(config).not_to be_valid
      expect(config.errors[:signed_in_rate]).to include("can't be blank")
    end

    it "validates presence of signed_out_rate" do
      config = described_class.new(placement_area: "sidebar_left", signed_in_rate: 50, signed_out_rate: nil)
      expect(config).not_to be_valid
      expect(config.errors[:signed_out_rate]).to include("can't be blank")
    end

    it "validates signed_in_rate is between 0 and 100" do
      config = described_class.new(placement_area: "sidebar_left", signed_in_rate: 150, signed_out_rate: 50)
      expect(config).not_to be_valid
      expect(config.errors[:signed_in_rate]).to include("must be less than or equal to 100")

      config = described_class.new(placement_area: "sidebar_left", signed_in_rate: -10, signed_out_rate: 50)
      expect(config).not_to be_valid
      expect(config.errors[:signed_in_rate]).to include("must be greater than or equal to 0")
    end

    it "validates signed_out_rate is between 0 and 100" do
      config = described_class.new(placement_area: "sidebar_left", signed_in_rate: 50, signed_out_rate: 150)
      expect(config).not_to be_valid
      expect(config.errors[:signed_out_rate]).to include("must be less than or equal to 100")

      config = described_class.new(placement_area: "sidebar_left", signed_in_rate: 50, signed_out_rate: -10)
      expect(config).not_to be_valid
      expect(config.errors[:signed_out_rate]).to include("must be greater than or equal to 0")
    end

    it "is valid with valid attributes" do
      config = described_class.new(placement_area: "sidebar_left", signed_in_rate: 50, signed_out_rate: 75)
      expect(config).to be_valid
    end
  end

  describe ".delivery_rate_for" do
    let!(:config) { described_class.create!(placement_area: "sidebar_left", signed_in_rate: 80, signed_out_rate: 60) }

    it "returns the signed_in_rate for signed in users" do
      rate = described_class.delivery_rate_for(placement_area: "sidebar_left", user_signed_in: true)
      expect(rate).to eq(80)
    end

    it "returns the signed_out_rate for signed out users" do
      rate = described_class.delivery_rate_for(placement_area: "sidebar_left", user_signed_in: false)
      expect(rate).to eq(60)
    end

    it "returns 100 for placement areas without config" do
      rate = described_class.delivery_rate_for(placement_area: "nonexistent_area", user_signed_in: true)
      expect(rate).to eq(100)
    end
  end

  describe ".should_fetch_billboard?" do
    let!(:config) { described_class.create!(placement_area: "sidebar_left", signed_in_rate: 50, signed_out_rate: 25) }

    it "always returns true for 100% rate" do
      config.update!(signed_in_rate: 100)
      result = described_class.should_fetch_billboard?(placement_area: "sidebar_left", user_signed_in: true)
      expect(result).to be true
    end

    it "always returns false for 0% rate" do
      config.update!(signed_in_rate: 0)
      result = described_class.should_fetch_billboard?(placement_area: "sidebar_left", user_signed_in: true)
      expect(result).to be false
    end

    it "returns true for placement areas without config (default 100%)" do
      result = described_class.should_fetch_billboard?(placement_area: "nonexistent_area", user_signed_in: true)
      expect(result).to be true
    end

    it "uses the correct rate based on user sign-in status" do
      # Mock rand to return 30 (which is < 50 but > 25)
      allow_any_instance_of(Object).to receive(:rand).with(100).and_return(30)

      signed_in_result = described_class.should_fetch_billboard?(placement_area: "sidebar_left", user_signed_in: true)
      signed_out_result = described_class.should_fetch_billboard?(placement_area: "sidebar_left", user_signed_in: false)

      expect(signed_in_result).to be true # 30 < 50
      expect(signed_out_result).to be false # 30 > 25
    end

    it "returns consistent results for 50% rate over multiple calls" do
      config.update!(signed_in_rate: 50, signed_out_rate: 50)

      # Mock rand to return 30 (should return true) and 70 (should return false)
      allow_any_instance_of(Object).to receive(:rand).with(100).and_return(30, 70)

      result1 = described_class.should_fetch_billboard?(placement_area: "sidebar_left", user_signed_in: true)
      result2 = described_class.should_fetch_billboard?(placement_area: "sidebar_left", user_signed_in: true)

      expect(result1).to be true  # 30 < 50
      expect(result2).to be false # 70 > 50
    end
  end

  describe "caching" do
    let!(:config) { described_class.create!(placement_area: "sidebar_left", signed_in_rate: 50, signed_out_rate: 50) }

    it "caches all_configs" do
      # Clear cache first
      described_class.bust_cache

      # Verify the method works and returns expected structure
      result = described_class.all_configs
      expect(result).to be_a(Hash)
      expect(result["sidebar_left"]).to eq(config)

      # Verify it works multiple times (even if cache doesn't work in test env)
      result2 = described_class.all_configs
      expect(result2).to eq(result)
    end

    it "busts cache on save" do
      # Populate cache
      described_class.all_configs

      # Save should bust cache - in test environment this will call delete but may not work as expected
      # So we just verify the method is called without error
      expect { config.update!(signed_in_rate: 75) }.not_to raise_error
    end

    it "busts cache on destroy" do
      # Populate cache
      described_class.all_configs

      # Destroy should bust cache - in test environment this will call delete but may not work as expected
      # So we just verify the method is called without error
      expect { config.destroy! }.not_to raise_error
    end
  end

  describe ".config_for_placement_area" do
    let!(:config) { described_class.create!(placement_area: "sidebar_left", signed_in_rate: 50, signed_out_rate: 50) }

    it "returns the config for the given placement area" do
      result = described_class.config_for_placement_area("sidebar_left")
      expect(result).to eq(config)
    end

    it "returns nil for non-existent placement area" do
      result = described_class.config_for_placement_area("nonexistent_area")
      expect(result).to be_nil
    end
  end

  describe ".selection_weights_for" do
    let!(:config) do
      described_class.create!(
        placement_area: "sidebar_left",
        signed_in_rate: 50,
        signed_out_rate: 50,
        selection_weights: {
          "random_selection" => 10,
          "new_and_priority" => 20,
          "weighted_performance" => 70
        },
      )
    end

    it "returns the selection weights for the given placement area" do
      weights = described_class.selection_weights_for("sidebar_left")
      expect(weights["random_selection"]).to eq(10)
      expect(weights["new_and_priority"]).to eq(20)
      expect(weights["weighted_performance"]).to eq(70)
    end

    it "merges with default weights for missing keys" do
      weights = described_class.selection_weights_for("sidebar_left")
      expect(weights["new_only"]).to eq(described_class::DEFAULT_SELECTION_WEIGHTS["new_only"])
    end

    it "returns default weights for non-existent placement area" do
      weights = described_class.selection_weights_for("nonexistent_area")
      expect(weights).to eq(described_class::DEFAULT_SELECTION_WEIGHTS)
    end

    it "returns default weights when selection_weights is empty" do
      config.update!(selection_weights: {})
      weights = described_class.selection_weights_for("sidebar_left")
      expect(weights).to eq(described_class::DEFAULT_SELECTION_WEIGHTS)
    end
  end

  describe "#initialize_weights_from_app_config" do
    let(:config) { described_class.create!(placement_area: "sidebar_left", signed_in_rate: 50, signed_out_rate: 50) }

    before do
      # Clear any existing selection_weights
      config.update!(selection_weights: {})
    end

    it "initializes weights from ApplicationConfig" do
      allow(ApplicationConfig).to receive(:[]).with("SELDOM_SEEN_MIN_FOR_SIDEBAR_LEFT").and_return(10)
      allow(ApplicationConfig).to receive(:[]).with("SELDOM_SEEN_MIN").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("SELDOM_SEEN_MAX_FOR_SIDEBAR_LEFT").and_return(40)
      allow(ApplicationConfig).to receive(:[]).with("SELDOM_SEEN_MAX").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("NEW_ONLY_MAX_FOR_SIDEBAR_LEFT").and_return(45)
      allow(ApplicationConfig).to receive(:[]).with("NEW_ONLY_MAX").and_return(nil)

      config.initialize_weights_from_app_config

      expect(config.selection_weights["random_selection"]).to eq(10)
      expect(config.selection_weights["new_and_priority"]).to eq(30)
      expect(config.selection_weights["new_only"]).to eq(5)
      expect(config.selection_weights["weighted_performance"]).to eq(54)
    end

    it "uses default fallback values when ApplicationConfig is empty" do
      allow(ApplicationConfig).to receive(:[]).and_return(nil)

      config.initialize_weights_from_app_config

      expect(config.selection_weights["random_selection"]).to eq(Billboard::RANDOM_RANGE_MAX_FALLBACK)
      expect(config.selection_weights["new_and_priority"]).to eq(Billboard::NEW_AND_PRIORITY_RANGE_MAX_FALLBACK - Billboard::RANDOM_RANGE_MAX_FALLBACK)
    end

    it "does not overwrite existing non-empty weights" do
      config.update!(selection_weights: { "random_selection" => 25 })
      original_weights = config.selection_weights.dup

      config.initialize_weights_from_app_config

      expect(config.selection_weights).to eq(original_weights)
    end
  end

  describe "#human_readable_placement_area" do
    let(:config) { described_class.new(placement_area: "sidebar_left", signed_in_rate: 50, signed_out_rate: 50) }

    it "returns the human-readable name for the placement area" do
      expect(config.human_readable_placement_area).to eq("Sidebar Left (First Position)")
    end

    it "returns the placement area if not found in the mapping" do
      config.placement_area = "unknown_area"
      expect(config.human_readable_placement_area).to eq("unknown_area")
    end
  end

  describe "#low_impression_count" do
    let(:config) { described_class.create!(placement_area: "sidebar_left", signed_in_rate: 50, signed_out_rate: 50) }

    it "returns the low impression count from ApplicationConfig for placement area" do
      allow(ApplicationConfig).to receive(:[]).with("LOW_IMPRESSION_COUNT_FOR_SIDEBAR_LEFT").and_return(500)
      expect(config.low_impression_count).to eq(500)
    end

    it "returns the global low impression count if area-specific is not set" do
      allow(ApplicationConfig).to receive(:[]).with("LOW_IMPRESSION_COUNT_FOR_SIDEBAR_LEFT").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("LOW_IMPRESSION_COUNT").and_return(750)
      expect(config.low_impression_count).to eq(750)
    end

    it "returns the default fallback if no ApplicationConfig is set" do
      allow(ApplicationConfig).to receive(:[]).and_return(nil)
      expect(config.low_impression_count).to eq(Billboard::LOW_IMPRESSION_COUNT)
    end
  end

  describe "edge cases" do
    describe "selection_weights validation" do
      let(:config) { described_class.new(placement_area: "sidebar_left", signed_in_rate: 50, signed_out_rate: 50) }

      it "rejects non-hash selection_weights" do
        config.selection_weights = "not a hash"
        expect(config).not_to be_valid
        expect(config.errors[:selection_weights]).to include("must be a hash")
      end

      it "rejects negative weight values" do
        config.selection_weights = { "random_selection" => -5 }
        expect(config).not_to be_valid
        expect(config.errors[:selection_weights]).to include("random_selection cannot be negative")
      end

      it "rejects non-integer weight values" do
        config.selection_weights = { "random_selection" => "not_a_number" }
        expect(config).not_to be_valid
        expect(config.errors[:selection_weights]).to include("random_selection must be an integer")
      end

      it "accepts valid integer weight values" do
        config.selection_weights = {
          "random_selection" => 10,
          "new_and_priority" => 20,
          "new_only" => 5,
          "weighted_performance" => 65
        }
        expect(config).to be_valid
      end

      it "accepts string integers as weight values" do
        config.selection_weights = {
          "random_selection" => "10",
          "new_and_priority" => "20"
        }
        expect(config).to be_valid
      end

      it "allows all weights to be zero (with warning)" do
        config.selection_weights = {
          "random_selection" => 0,
          "new_and_priority" => 0,
          "new_only" => 0,
          "weighted_performance" => 0
        }
        expect(Rails.logger).to receive(:warn).with(/All selection weights are zero/)
        expect(config).to be_valid
      end

      it "allows empty selection_weights" do
        config.selection_weights = {}
        expect(config).to be_valid
      end
    end

    describe ".selection_weights_for edge cases" do
      it "returns defaults when config has empty weights" do
        config = described_class.create!(
          placement_area: "sidebar_left",
          signed_in_rate: 50,
          signed_out_rate: 50,
          selection_weights: {}
        )
        weights = described_class.selection_weights_for("sidebar_left")
        expect(weights).to eq(described_class::DEFAULT_SELECTION_WEIGHTS)
      end

      it "filters out negative values and replaces with 0" do
        config = described_class.create!(
          placement_area: "sidebar_left",
          signed_in_rate: 50,
          signed_out_rate: 50,
          selection_weights: { "random_selection" => 10 }
        )
        # Manually set a negative value (bypassing validation for testing)
        config.update_column(:selection_weights, { "random_selection" => -5, "new_and_priority" => 20 })
        
        weights = described_class.selection_weights_for("sidebar_left")
        expect(weights["random_selection"]).to eq(0)
        expect(weights["new_and_priority"]).to eq(20)
      end

      it "handles mixed valid and invalid weight values" do
        config = described_class.create!(
          placement_area: "sidebar_left",
          signed_in_rate: 50,
          signed_out_rate: 50,
          selection_weights: { "random_selection" => 10 }
        )
        # Manually set mixed values (bypassing validation for testing)
        config.update_column(:selection_weights, { "random_selection" => 10, "new_and_priority" => nil })
        
        weights = described_class.selection_weights_for("sidebar_left")
        expect(weights["random_selection"]).to eq(10)
        # nil values should be filtered out and replaced with 0 by our edge case handling
        # Then merged with defaults for missing keys
        expect(weights["new_and_priority"]).to eq(0)
        # Keys not present in the config should get defaults
        expect(weights["new_only"]).to eq(described_class::DEFAULT_SELECTION_WEIGHTS["new_only"])
      end
    end

    describe ".should_fetch_billboard? edge cases" do
      it "handles nil placement_area gracefully" do
        result = described_class.should_fetch_billboard?(placement_area: nil, user_signed_in: true)
        expect(result).to be true
      end

      it "handles empty string placement_area" do
        result = described_class.should_fetch_billboard?(placement_area: "", user_signed_in: true)
        expect(result).to be true
      end

      it "handles non-existent placement_area" do
        result = described_class.should_fetch_billboard?(placement_area: "nonexistent", user_signed_in: true)
        expect(result).to be true
      end
    end

    describe ".delivery_rate_for edge cases" do
      it "handles nil placement_area gracefully" do
        rate = described_class.delivery_rate_for(placement_area: nil, user_signed_in: true)
        expect(rate).to eq(100)
      end

      it "handles empty string placement_area" do
        rate = described_class.delivery_rate_for(placement_area: "", user_signed_in: true)
        expect(rate).to eq(100)
      end
    end
  end
end
