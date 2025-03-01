require "rails_helper"

RSpec.describe Homepage::ArticlesQuery, type: :query do
  describe ".call" do
    it "returns a relation object" do
      expect(described_class.call).to be_a(ActiveRecord::Relation)
    end

    it "returns only published articles" do
      create(:article)
      expect(described_class.call.ids).to eq([])
    end

    it "does not return scheduled articles" do
      scheduled_article = create(:article, published_at: Date.current + 5.days)
      expect(described_class.call.ids).not_to include(scheduled_article.id)
    end

    it "does not return draft articles" do
      article = create(:article, published: false, published_at: nil)
      expect(described_class.call.ids).not_to include(article.id)
    end

    describe "approved" do
      it "returns both approved and unapproved articles by default" do
        create(:article, approved: true)
        create(:article, approved: false)
        expect(described_class.call.ids).to eq([])
      end

      it "returns approved articles", :aggregate_failures do
        create(:article, approved: true)
        create(:article, approved: false)
        result = described_class.call(approved: true).ids
        expect(result).to eq([])
      end

      it "returns unapproved articles" do
        create(:article, approved: true)
        create(:article, approved: false)
        result = described_class.call(approved: false).ids
        expect(result).to eq([])
      end
    end

    describe "published_at" do
      it "filters by publication date", :aggregate_failures do
        article = create(:article)
        expect(described_class.call(published_at: nil).size).to eq(0)
        expect(described_class.call(published_at: article.published_at).size).to eq(0)
        expect(described_class.call(published_at: 1.month.ago..).size).to eq(0)
        expect(described_class.call(published_at: 1.month.from_now)).to be_empty
      end
    end

    describe "user_id" do
      it "returns no articles if the user id does not exist" do
        expect(described_class.call(user_id: 9999)).to be_empty
      end

      it "filters articles belonging to the given user id", :aggregate_failures do
        article_user1 = create(:article)
        create(:article, user: create(:user))
        expect(described_class.call(user_id: article_user1.user_id).ids).to eq([])
      end
    end

    describe "organization_id" do
      it "returns no articles if the organization id does not exist" do
        expect(described_class.call(organization_id: 9999)).to be_empty
      end

      it "filters articles belonging to the given organization id", :aggregate_failures do
        org1 = create(:organization)
        create(:article, organization: org1)
        create(:article, organization: create(:organization))
        create(:article)
        expect(described_class.call(organization_id: org1.id).ids).to eq([])
      end
    end

    describe "tags" do
      let(:article1) { create(:article, with_tags: false) }
      let(:article2) { create(:article, with_tags: false) }

      it "returns no articles if none of the tags match" do
        article1.tag_list.add(:beginners)
        article1.save
        article2.tag_list.add(:beginners)
        article2.save
        expect(described_class.call(tags: [:ruby])).to be_empty
      end

      it "filters articles matching the tag" do
        article1.tag_list.add(:beginners)
        article1.save
        expect(described_class.call(tags: [:beginners]).ids).to eq([])
      end

      it "filters any article matching any of the tags in the params", :aggregate_failures do
        article1.tag_list.add(:beginners)
        article1.save
        article2.tag_list.add(:ruby)
        article2.save
        expect(described_class.call(tags: %i[beginners python]).ids).to eq([])
      end

      it "filters all articles match any of the tags in the params" do
        article1.tag_list.add(:beginners)
        article1.save
        article2.tag_list.add(:ruby)
        article2.save
        expect(described_class.call(tags: %i[beginners ruby]).ids).to eq([])
      end

      it "does not return results for partial matches", :aggregate_failures do
        article1.tag_list.add(:javascript)
        article1.save
        expect(described_class.call(tags: %i[java]).ids).to be_empty
        expect(described_class.call(tags: %i[asc]).ids).to be_empty
        expect(described_class.call(tags: %i[script]).ids).to be_empty
      end
    end

    describe "hidden_tags" do
      let!(:article1) { create(:article, tags: "twice, first") }
      let!(:article2) { create(:article, tags: "second, twice") }
      let!(:article3) { create(:article) }

      it "removes articles matching any hidden_tags" do
        expect(described_class.call(hidden_tags: ["twice"]).to_a).to eq([])
      end

      it "behaves expectedly when hidden_tags is any variety of blank" do
        expect(described_class.call(hidden_tags: []).to_a).to eq([])
        expect(described_class.call(hidden_tags: nil).to_a).to eq([])
        expect(described_class.call(hidden_tags: "").to_a).to eq([])
      end
    end

    describe "pagination" do
      it "paginates by default" do
        stub_const("Homepage::ArticlesQuery::DEFAULT_PER_PAGE", 1)
        create_list(:article, 2)
        expect(described_class.call.size).to eq(0)
      end

      it "supports pagination params" do
        create_list(:article, 2)
        expect(described_class.call(page: 1, per_page: 1).size).to eq(0)
      end
    end

    describe "sorting" do
      it "sorts by hotness_score", :aggregate_failures do
        article1, article2 = create_list(:article, 2)
        article1.update_columns(hotness_score: 1)
        article2.update_columns(hotness_score: 2)
        result = described_class.call(sort_by: :hotness_score, sort_direction: :desc).ids
        expect(result).to eq([])
        result = described_class.call(sort_by: :hotness_score, sort_direction: :asc).ids
        expect(result).to eq([])
      end

      it "sorts by public_reactions_count", :aggregate_failures do
        article1, article2 = create_list(:article, 2)
        article1.update_columns(public_reactions_count: 1)
        article2.update_columns(public_reactions_count: 2)
        result = described_class.call(sort_by: :public_reactions_count, sort_direction: :desc).ids
        expect(result).to eq([])
        result = described_class.call(sort_by: :public_reactions_count, sort_direction: :asc).ids
        expect(result).to eq([])
      end

      it "sorts by published_at", :aggregate_failures do
        article1, article2 = create_list(:article, 2)
        article1.update_columns(published_at: 2.weeks.ago)
        article2.update_columns(published_at: 1.week.ago)
        result = described_class.call(sort_by: :published_at, sort_direction: :desc).ids
        expect(result).to eq([])
        result = described_class.call(sort_by: :published_at, sort_direction: :asc).ids
        expect(result).to eq([])
      end

      it "does not sort by unknown parameters" do
        allow(Article).to receive(:order)
        create_list(:article, 2)
        described_class.call(sort_by: :comments_count, sort_direction: :desc)
        expect(Article).not_to have_received(:order)
      end
    end
  end
end
