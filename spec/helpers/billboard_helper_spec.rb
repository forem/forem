require "rails_helper"

describe BillboardHelper do
  describe ".billboards_placement_area_options_array" do
    it "returns proper human value" do
      expect(helper.billboards_placement_area_options_array[1]).to eq ["Sidebar Left (Second Position)",
                                                                        "sidebar_left_2"]
    end
  end
end
