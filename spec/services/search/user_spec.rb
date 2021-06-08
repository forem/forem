require "rails_helper"

# rubocop:disable Rails/PluckId
# This spec uses `pluck` on an array of hashes, but Rubocop can't tell the difference.
RSpec.describe Search::User, type: :service do
  describe "::search_documents" do
    it "returns an empty result if there are no users" do
      expect(described_class.search_documents).to be_empty
    end

    it "does not return suspended users" do
      user = create(:user, :suspended)

      expect(described_class.search_documents.pluck(:id)).not_to include(user.id)
    end

    it "returns regular users" do
      user = create(:user)

      expect(described_class.search_documents.pluck(:id)).to include(user.id)
    end

    it "returns admins" do
      user = create(:user, :super_admin)

      expect(described_class.search_documents.pluck(:id)).to include(user.id)
    end

    context "when describing the result format" do
      let(:results) { described_class.search_documents }

      it "returns the correct attributes for a single result", :aggregate_failures do
        user = create(:user)

        result = results.first

        expect(result.keys).to match_array(%i[class_name id path title user])
        expect(result[:class_name]).to eq("User")
        expect(result[:id]).to eq(user.id)
        expect(result[:path]).to eq(user.path)
        expect(result[:title]).to eq(user.name)

        expect(result[:user][:name]).to eq(user.username)
        expect(result[:user][:profile_image_90]).to eq(user.profile_image_90)
        expect(result[:user][:username]).to eq(user.username)
      end
    end

    context "when searching for a term" do
      let(:user) { create(:user) }

      it "matches against the user's name", :aggregate_failures do
        user.update_columns(name: "Langston Hughes")

        result = described_class.search_documents(term: "lang")
        expect(result.first[:id]).to eq(user.id)

        result = described_class.search_documents(term: "fiesta")
        expect(result).to be_empty
      end

      it "matches against the user's username", :aggregate_failures do
        result = described_class.search_documents(term: user.username.first(3))
        expect(result.first[:id]).to eq(user.id)

        result = described_class.search_documents(term: "fiesta")
        expect(result).to be_empty
      end
    end

    context "when sorting" do
      it "sorts by 'hotness_score' in descending order by default" do
        user1, user2 = create_list(:user, 2)

        user1.update_columns(articles_count: 10, reputation_modifier: 1.0)
        user2.update_columns(articles_count: 10, reputation_modifier: 2.2)

        results = described_class.search_documents
        expect(results.pluck(:id)).to eq([user2.id, user1.id])
      end

      it "supports sorting by created_at in ascending and descending order", :aggregate_failures do
        user1 = create(:user)

        user2 = nil
        Timecop.travel(1.week.ago) do
          user2 = create(:user)
        end

        results = described_class.search_documents(sort_by: :created_at, sort_direction: :asc)
        expect(results.pluck(:id)).to eq([user2.id, user1.id])

        results = described_class.search_documents(sort_by: :created_at, sort_direction: :desc)
        expect(results.pluck(:id)).to eq([user1.id, user2.id])
      end
    end

    context "when paginating" do
      it "returns no items when out of pagination bounds" do
        create_list(:user, 2)

        result = described_class.search_documents(page: 99)
        expect(result).to be_empty
      end

      it "returns paginated items", :aggregate_failures do
        create_list(:user, 2)

        result = described_class.search_documents(page: 0, per_page: 1)
        expect(result.length).to eq(1)

        result = described_class.search_documents(page: 1, per_page: 1)
        expect(result.length).to eq(1)
      end
    end
  end
end
# rubocop:enable Rails/PluckId
