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
    let(:billboard) { build(:billboard, name: "Manual Test", audience_segment: target_segment) }

    it "returns a single option with the billboard's audience segment" do
      expect(options).to include(["Managed elsewhere", target_segment.id])
      expect(options).not_to include(["Managed elsewhere", different_segment.id])
    end

    context "when the billboard doesn't have an audience segment" do
      let(:billboard) { build(:billboard, name: "No Audience Segment") }

      it "raises ArgumentError" do
        expect { options }.to raise_error(ArgumentError, /must have a target audience segment/)
      end
    end
  end

  describe "#billboard_async_path" do
    let(:article) { create(:article) }
    let(:article_path) do
      article_billboard_path(username: article.username, slug: article.slug, placement_area: :post_comments)
    end

    it "loads billboards in the context of the article or page by default" do
      expect(helper.billboard_async_path(:post_comments, article: article)).to eq(article_path)
      expect(helper.billboard_async_path(:page_fixed_bottom, page_id: 5))
        .to eq(billboard_path(page_id: 5, placement_area: :page_fixed_bottom))
    end

    context "when the placement area is fully cached" do
      before do
        BillboardPlacementAreaConfig.create!(placement_area: "post_comments", fully_cached: true)
        BillboardPlacementAreaConfig.create!(placement_area: "page_fixed_bottom", fully_cached: true)
      end

      it "loads billboards from one URL shared by every article and page" do
        expect(helper.billboard_async_path(:post_comments, article: article))
          .to eq(billboard_path(placement_area: :post_comments))
        expect(helper.billboard_async_path(:page_fixed_bottom, page_id: 5))
          .to eq(billboard_path(placement_area: :page_fixed_bottom))
      end

      it "keeps the article's own URL when its author opts out of adjacent sponsors" do
        article.user.setting.update!(permit_adjacent_sponsors: false)

        expect(helper.billboard_async_path(:post_comments, article: article)).to eq(article_path)
      end
    end
  end
end
