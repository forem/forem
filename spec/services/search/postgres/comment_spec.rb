require "rails_helper"

RSpec.describe Search::Postgres::Comment, type: :service do
  let(:comment) { create(:comment) }

  describe "::search_documents" do
    context "when filtering Commentables" do
      it "does not include comments from Articles that are unpublished", :aggregate_failures do
        comment_text = "Ruby on Rails rocks!"
        published_article = create(:article, title: "Published Article", published: true)
        unpublished_article = create(:article, title: "Unpublished Article", published: true)
        comment_on_published_article = create(:comment, body_markdown: comment_text, commentable: published_article)
        comment_on_unpublished_article = create(:comment, body_markdown: comment_text, commentable: unpublished_article)
        unpublished_article.update_columns(published: false)

        result = described_class.search_documents(term: "rails")
        # rubocop:disable Rails/PluckId
        ids = result.pluck(:id)
        # rubocop:enable Rails/PluckId

        expect(ids).not_to include(comment_on_unpublished_article.search_id)
        expect(ids).to include(comment_on_published_article.search_id)
      end
    end

    context "when describing the result format" do
      let(:result) { described_class.search_documents(term: comment.body_markdown) }

      it "returns the correct attributes for the result" do
        expected_keys = %i[
          id path public_reactions_count body_text class_name highlight
          hotness_score published published_at readable_publish_date_string
          title user
        ]

        expect(result.first.keys).to match_array(expected_keys)
      end

      it "returns the correct attributes for the user" do
        expected_keys = %i[username name profile_image_90]
        expect(result.first[:user].keys).to match_array(expected_keys)
      end

      it "returns highlights" do
        expected_keys = %i[body_text]
        expect(result.first[:highlight].keys).to match_array(expected_keys)
        highlights = result.first[:highlight][:body_text].first
        expect(highlights).to include("<mark>", "</mark>")
      end

      it "orders the results by score (hotness_score) in descending order by default" do
        comment_text = "Ruby on Rails rocks!"
        comment = create(:comment, body_markdown: comment_text, score: 0)
        hotter_comment = create(:comment, body_markdown: comment_text, score: 99)

        result = described_class.search_documents(term: "rails")
        scores = result.pluck(:hotness_score)

        expect(scores).to eq([hotter_comment.score, comment.score])
      end

      it "orders the results by published_at (created_at) in descending order" do
        comment_text = "Ruby on Rails rocks!"
        comment = create(:comment, body_markdown: comment_text, score: 0)
        older_comment = create(:comment, body_markdown: comment_text, score: 99, created_at: 1.day.ago)

        result = described_class.search_documents(sort_by: "published_at", sort_direction: "desc", term: "rails")
        # rubocop:disable Rails/PluckId
        ids = result.pluck(:id)
        # rubocop:enable Rails/PluckId

        expect(ids).to eq([comment.search_id, older_comment.search_id])
      end

      it "orders the results by published_at (created_at) in ascending order" do
        comment_text = "Ruby on Rails rocks!"
        comment = create(:comment, body_markdown: comment_text, score: 0)
        older_comment = create(:comment, body_markdown: comment_text, score: 99, created_at: 1.day.ago)

        result = described_class.search_documents(sort_by: "published_at", sort_direction: "asc", term: "rails")
        # rubocop:disable Rails/PluckId
        ids = result.pluck(:id)
        # rubocop:enable Rails/PluckId

        expect(ids).to eq([older_comment.search_id, comment.search_id])
      end
    end

    context "when searching for a term" do
      it "matches against the comment's body_markdown (body_text)", :aggregate_failures do
        comment.update_columns(body_markdown: "Ruby on Rails rocks!")
        result = described_class.search_documents(term: "rails")

        expect(result.first[:body_text]).to eq comment.body_markdown

        result = described_class.search_documents(term: "javascript")
        expect(result).to be_empty
      end
    end

    context "when paginating" do
      before { create_list(:comment, 2) }

      it "returns no results when out of pagination bounds" do
        result = described_class.search_documents(page: 99)
        expect(result).to be_empty
      end

      it "returns paginated results", :aggregate_failures do
        result = described_class.search_documents(page: 0, per_page: 1)
        expect(result.length).to eq(1)

        result = described_class.search_documents(page: 1, per_page: 1)
        expect(result.length).to eq(1)
      end
    end
  end
end
