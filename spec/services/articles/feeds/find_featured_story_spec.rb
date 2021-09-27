require "rails_helper"

RSpec.describe Articles::Feeds::FindFeaturedStory, type: :service do
  before { create(:article) }

  context "when passed an ActiveRecord collection" do
    it "returns first article with a main image" do
      featured_story = described_class.call(Article.all)
      expect(featured_story.main_image).not_to be_nil
    end
  end

  context "when passed an array" do
    it "returns first article with a main image" do
      featured_story = described_class.call(Article.all.to_a)
      expect(featured_story.main_image).to be_present
    end
  end

  context "when passed collection without any articles" do
    it "returns an new, empty Article object" do
      expect(described_class.call([])).not_to be_persisted
    end
  end
end
