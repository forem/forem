require "rails_helper"

RSpec.describe Articles::Feeds::Tag, type: :service do
  let(:tag) { "tag" }
  let!(:article) { create(:article) }
  let!(:tagged_article) { create(:article, tags: tag) }
  let!(:unpublished_article) { create(:article, published: false) }

  it "returns published articles only" do
    result = described_class.call
    expect(result).to include article
    expect(result).not_to include unpublished_article
  end

  context "with tag" do
    it "returns articles with the specified tag" do
      expect(described_class.call(tag)).to include tagged_article
    end
  end

  it "loads the feed without querying reactions" do
    create(:reaction, reactable: tagged_article, category: "like")
    reaction_queries = []
    callback = lambda do |_name, _start, _finish, _id, payload|
      reaction_queries << payload[:sql] if payload[:sql].include?('"reactions"')
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { described_class.call(tag).load }

    expect(reaction_queries).to be_empty
  end

  it "still returns the reaction categories of each article" do
    create(:reaction, reactable: tagged_article, category: "like")

    story = described_class.call(tag).find { |article| article.id == tagged_article.id }

    expect(story.public_reaction_categories.map(&:slug)).to eq([:like])
  end
end
