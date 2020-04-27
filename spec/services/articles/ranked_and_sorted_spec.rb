require "rails_helper"

RSpec.describe Articles::RankedAndSorted, type: :service do
  describe "#rank_and_sort_articles" do
    let(:article1) { create(:article) }
    let(:article2) { create(:article) }
    let(:article3) { create(:article) }
    let(:user) { create(:user) }
    let(:articles) { [article1, article2, article3] }
    let(:tag_weight) { 1 }
    let(:randomness) { 3 }
    let(:comment_weight) { 0 }
    let(:experience_level_weight) { 1 }
    let(:ranked) do
      described_class.new(
        articles: articles,
        user: user,
        tag_weight: tag_weight,
        randomness: randomness,
        comment_weight: comment_weight,
        experience_level_weight: experience_level_weight,
      )
    end

    context "when number of articles specified" do
      before { ranked.instance_variable_set(:@number_of_articles, 1) }

      it "only returns the requested number of articles" do
        expect(ranked.perform.size).to eq 1
      end
    end

    context "when is given different articles" do
      before do
        article1.comments_count = 1
        article2.comments_count = 10
        article3.comments_count = 100
        articles = [article1, article2, article3]
        ranked.instance_variable_set(:@number_of_articles, 3)
        ranked.instance_variable_set(:@comment_weight, 2)
        ranked.instance_variable_set(:@articles, articles)
      end

      it "returns article with the most score" do
        expect(ranked.perform).to eq [article3, article2, article1]
      end
    end
  end
end
