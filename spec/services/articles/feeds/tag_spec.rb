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
end
