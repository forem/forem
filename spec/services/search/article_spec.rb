require "rails_helper"

# rubocop:disable Rails/PluckId
# This spec uses `pluck` on an array of hashes, but Rubocop can't tell the difference.
RSpec.describe Search::Article, type: :service do
  describe "::search_documents" do
    it "returns an empty result if there are no articles" do
      expect(described_class.search_documents).to be_empty
    end

    it "does not return unpublished articles" do
      article = create(:article, published: false)

      expect(described_class.search_documents.pluck(:id)).not_to include(article.id)
    end

    it "returns published articles" do
      article = create(:article)

      expect(described_class.search_documents.pluck(:id)).to include(article.id)
    end

    context "when describing the result format" do
      it "does not include a highlight attribute" do
        create(:article)

        expect(described_class.search_documents.first.key?(:highlight)).to be(false)
      end
    end

    context "when filtering by user_id" do
      it "returns articles belonging to a specific user", :aggregate_failures do
        user = create(:user)
        articles = create_list(:article, 2, user: user)
        article = create(:article)

        results = described_class.search_documents(user_id: user.id).pluck(:id)
        expect(results).not_to include(article.id)
        expect(results).to match_array(articles.pluck(:id))
      end
    end

    context "when searching for a term" do
      let(:article) { create(:article) }

      it "matches against the article's body_markdown", :aggregate_failures do
        article.update_columns(body_markdown: "Life of the party")

        result = described_class.search_documents(term: "part").first
        expect(result[:path]).to eq(article.path)

        results = described_class.search_documents(term: "fiesta")
        expect(results).to be_empty
      end

      it "matches against the article's title", :aggregate_failures do
        article.update_columns(title: "Life of the party")

        result = described_class.search_documents(term: "part").first
        expect(result[:path]).to eq(article.path)

        results = described_class.search_documents(term: "fiesta")
        expect(results).to be_empty
      end

      it "matches against the article's tags", :aggregate_failures do
        article.update_columns(cached_tag_list: "javascript, beginners, ruby")

        result = described_class.search_documents(term: "beginner").first
        expect(result[:path]).to eq(article.path)

        results = described_class.search_documents(term: "newbie")
        expect(results).to be_empty
      end

      it "matches against the article's organization's name", :aggregate_failures do
        article.organization = create(:organization, name: "ACME corp")
        article.save!

        result = described_class.search_documents(term: "ACME").first
        expect(result[:path]).to eq(article.path)

        results = described_class.search_documents(term: "ECMA")
        expect(results).to be_empty
      end

      it "matches against the article's user's name", :aggregate_failures do
        result = described_class.search_documents(term: article.user_name.first(3)).first
        expect(result[:path]).to eq(article.path)

        results = described_class.search_documents(term: "notaname")
        expect(results).to be_empty
      end

      it "matches against the article's user's username", :aggregate_failures do
        result = described_class.search_documents(term: article.user_username.first(3)).first
        expect(result[:path]).to eq(article.path)

        results = described_class.search_documents(term: "notausername")
        expect(results).to be_empty
      end
    end

    context "when sorting" do
      it "sorts by 'hotness_score' and 'comments_count' in descending order by default" do
        article1, article2, article3 = create_list(:article, 3)

        article1.update_columns(hotness_score: 10, comments_count: 10)
        article2.update_columns(hotness_score: 10, comments_count: 11)
        article3.update_columns(hotness_score: 9, comments_count: 20)

        results = described_class.search_documents
        expect(results.pluck(:id)).to eq([article2.id, article1.id, article3.id])
      end

      it "supports sorting by published_at in ascending and descending order", :aggregate_failures do
        article1 = create(:article)

        article2 = nil
        Timecop.travel(1.week.ago) do
          article2 = create(:article)
        end

        results = described_class.search_documents(sort_by: :published_at, sort_direction: :asc)
        expect(results.pluck(:id)).to eq([article2.id, article1.id])

        results = described_class.search_documents(sort_by: :published_at, sort_direction: :desc)
        expect(results.pluck(:id)).to eq([article1.id, article2.id])
      end
    end

    context "when paginating" do
      it "returns no items when out of pagination bounds" do
        create(:article)

        result = described_class.search_documents(page: 99)
        expect(result).to be_empty
      end

      it "returns paginated items", :aggregate_failures do
        create_list(:article, 2)

        result = described_class.search_documents(page: 0, per_page: 1)
        expect(result.length).to eq(1)

        result = described_class.search_documents(page: 1, per_page: 1)
        expect(result.length).to eq(1)
      end
    end
  end
end
# rubocop:enable Rails/PluckId
