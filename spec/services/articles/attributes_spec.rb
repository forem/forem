require "rails_helper"

RSpec.describe Articles::Attributes, type: :service do
  describe "#for_update" do
    let(:user) { create(:user) }

    context "when few attributes" do
      let(:few_attributes) do
        {
          body_markdown: "---\ntitle: Title\npublished: false\ndescription:\ntags: heytag\n---\n\nHey this is the article",
          organization_id: 2
        }
      end
      let(:attrs_for_update) { described_class.new(few_attributes, user).for_update }

      it "doesn't have attributes that were not passed" do
        expect(attrs_for_update.key?(:title)).to be false
        expect(attrs_for_update.key?(:video_thumbnail_url)).to be false
      end

      it "has passed attributes" do
        expect(attrs_for_update[:body_markdown]).to include("Hey this is the article")
        expect(attrs_for_update[:organization_id]).to eq(2)
      end
    end

    context "more attributes" do
      it "sets collection when :series was passed" do
        series_attrs = described_class.new({ series: "slug", title: "title" }, user).for_update
        expect(series_attrs[:collection]).to be_a(Collection)
        expect(series_attrs[:series]).to be nil
      end

      it "resets the collection when empty :series was passed" do
        no_series_attrs = described_class.new({ series: "" }, user).for_update
        expect(no_series_attrs[:collection]).to be nil
        expect(no_series_attrs[:series]).to be nil
      end

      # или это не надо, не поняла?
      it "doesn't have the collection when :series was not passed" do

      end

      it "sets tag_list when tags were passed" do

      end

      it "sets tag_list when tag_list was passed" do
      end
    end
  end
end
