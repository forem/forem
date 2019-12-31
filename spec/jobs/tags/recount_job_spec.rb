require "rails_helper"

RSpec.describe Tags::RecountJob do
  include_examples "#enqueues_job", "tag_recount", 1

  describe "#perform_now" do
    let(:article) { create(:article) }
    let(:tag) { Tag.find_by(name: article.decorate.cached_tag_list_array.first) }

    before do
      described_class.perform_now(article.id)
    end

    it "counts articles" do
      expect(tag.sortable_counts.size).to be(6)
      expect(tag.sortable_counts.first.slug).to eq("published_articles_this_7_days")
    end

    it "counts comments" do
      expect(tag.sortable_counts.size).to be(6)
      expect(tag.sortable_counts.where(slug: "comments_this_7_days").size).to be(1)
    end

    it "counts reactions" do
      expect(tag.sortable_counts.size).to eq(6)
      expect(tag.sortable_counts.where(slug: "reactions_this_7_days").size).to be(1)
    end
  end
end
