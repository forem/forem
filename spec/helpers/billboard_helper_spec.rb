require "rails_helper"

describe BillboardHelper do
  describe ".billboards_placement_area_options_array" do
    it "returns proper human value" do
      expect(helper.billboards_placement_area_options_array[1]).to eq ["Sidebar Left (Second Position)",
                                                                       "sidebar_left_2"]
    end
  end

  describe ".automatic_audience_segments_options_array" do
    subject(:options) { helper.automatic_audience_segments_options_array }

    let!(:no_posts) { create(:audience_segment, type_of: "no_posts_yet") }
    let!(:manual_1) { create(:audience_segment, type_of: "manual") }
    let!(:trusted) { create(:audience_segment, type_of: "trusted") }
    let!(:manual_2) { create(:audience_segment, type_of: "manual") }
    let!(:posted) { create(:audience_segment, type_of: "posted") }

    it "returns proper human values for only automatic segments" do
      expect(options).to include(
        ["Have not posted yet", no_posts.id],
        ["Are trusted", trusted.id],
        ["Have at least one post", posted.id],
      )

      expect(options).not_to include(
        ["Managed elsewhere", manual_1.id],
        ["Managed elsewhere", manual_2.id],
      )
    end
  end

  describe ".single_audience_segment_option" do
    subject(:options) { helper.single_audience_segment_option(billboard) }

    let(:target_segment) { create(:audience_segment, type_of: "manual") }
    let!(:different_segment) { create(:audience_segment, type_of: "manual") }
    let(:billboard) { build(:display_ad, name: "Manual Test", audience_segment: target_segment) }

    it "returns a single option with the billboard's audience segment" do
      expect(options).to include(["Managed elsewhere", target_segment.id])
      expect(options).not_to include(["Managed elsewhere", different_segment.id])
    end

    context "when the billboard doesn't have an audience segment" do
      let(:billboard) { build(:display_ad, name: "No Audience Segment") }

      it "raises ArgumentError" do
        expect { options }.to raise_error(ArgumentError, /must have a target audience segment/)
      end
    end
  end
end
