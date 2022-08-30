require "rails_helper"

RSpec.describe Articles::Attributes, type: :service do
  describe "#for_update" do
    let(:user) { create(:user) }

    context "when few attributes" do
      let(:few_attributes) do
        {
          body_markdown: "---\ntitle: Title\npublished: false\ndescription:\ntags: hey\n---\n\nHey this is the article",
          organization_id: 2
        }
      end
      let(:attrs_for_update) { described_class.new(few_attributes, user).for_update }

      it "has attributes that were passed as nils" do
        few_attributes[:title] = nil
        attrs = described_class.new(few_attributes, user).for_update
        expect(attrs.key?(:title)).to be true
        expect(attrs[:title]).to be_nil
      end

      it "doesn't have attributes that were not passed" do
        expect(attrs_for_update.key?(:title)).to be false
        expect(attrs_for_update.key?(:video_thumbnail_url)).to be false
      end

      it "has passed attributes" do
        expect(attrs_for_update[:body_markdown]).to include("Hey this is the article")
        expect(attrs_for_update[:organization_id]).to eq(2)
      end
    end

    it "sets a collection when :series was passed" do
      series_attrs = described_class.new({ series: "slug", title: "title" }, user).for_update
      expect(series_attrs[:collection]).to be_a(Collection)
      expect(series_attrs[:series]).to be_nil
    end

    it "resets the collection when empty :series was passed" do
      no_series_attrs = described_class.new({ series: "" }, user).for_update
      expect(no_series_attrs[:collection]).to be_nil
      expect(no_series_attrs[:series]).to be_nil
    end

    it "does not reset the collection when no :series was passed" do
      no_series_attrs = described_class.new({ title: "hello" }, user).for_update
      expect(no_series_attrs.key?(:collection)).to be false
    end

    it "sets tag_list when tags were passed" do
      tags_attrs = described_class.new({ tags: %w[ruby cpp], title: "title" }, user).for_update
      expect(tags_attrs[:tag_list]).to eq("ruby, cpp")
    end

    it "sets tag_list when tag_list was passed" do
      tags_attrs = described_class.new({ tag_list: "ruby, cpp", title: "title" }, user).for_update
      expect(tags_attrs[:tag_list]).to eq("ruby, cpp")
    end

    it "sets edited_at if update_edited_at is true" do
      attrs = described_class.new({ title: "title" }, user).for_update(update_edited_at: true)
      expect(attrs[:edited_at]).to be_truthy
    end

    it "doesn't set edited_at if update_edited_at is false" do
      attrs = described_class.new({ title: "title" }, user).for_update(update_edited_at: false)
      expect(attrs[:edited_at]).to be_falsey
    end

    it "sets published_at correctly" do
      attrs = described_class.new({ title: "title", published_at: "2022-04-25" }, user).for_update
      expect(attrs[:published_at]).to eq(DateTime.new(2022, 4, 25))
    end
  end
end
