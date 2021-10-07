require "rails_helper"

describe DisplayAdHelper, type: :helper do
  describe ".display_ads_placement_area_options_array" do
    it "returns proper human value" do
      expect(helper.display_ads_placement_area_options_array[1]).to eq ["Sidebar Left (Second Position)",
                                                                        "sidebar_left_2"]
    end
  end
end
