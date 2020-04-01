require "rails_helper"

RSpec.describe Internal::ModeratorsQuery, type: :query do
  let!(:user)  { create(:user, :trusted, name: "Greg") }
  let!(:user2) { create(:user, :trusted, name: "Gregory") }
  let!(:user3) { create(:user, :tag_moderator, name: "Paul", comments_count: 4) }
  let!(:user4) { create(:user, :admin, name: "Susi", comments_count: 10) }
  let!(:user5) { create(:user, :trusted, :admin, name: "Beth") }
  let!(:user6) { create(:user, :admin, name: "Jean", comments_count: 5) }

  describe ".call" do
    context "when no arguments are given" do
      it "returns all moderators" do
        expect(described_class.call).to eq([user, user2, user5])
      end
    end

    context "when search is set" do
      let(:options) { { search: "greg" } }

      it "returns the users with correct name" do
        expect(described_class.call(User.all, options)).to eq([user, user2])
      end
    end

    context "when state is tag_moderator" do
      let(:options) { { state: "tag_moderator" } }

      it "returns all tag moderators" do
        expect(described_class.call(User.all, options)).to eq([user3])
      end
    end

    context "when state is potential" do
      let(:options) { { state: "potential" } }

      it "returns all non moderators ordered by comments_count" do
        expect(described_class.call(User.all, options)).to eq([user4, user6, user3])
      end
    end

    context "when state does not exist" do
      let(:options) { { state: "non_existent_role" } }

      it "returns all non moderators ordered by comments_count" do
        expect(described_class.call(User.all, options)).to be_empty
      end
    end
  end
end
