require "rails_helper"

RSpec.describe Admin::ModeratorsQuery, type: :query do
  subject { described_class.call(options: options) }

  let!(:user) { create(:user, :trusted, name: "Greg") }
  let(:user2) { create(:user, :trusted, name: "Gregory") }
  let!(:user3) { create(:user, :tag_moderator, name: "Paul", comments_count: 4) }
  let!(:user4) { create(:user, :admin, name: "Susi", comments_count: 10) }
  let(:user5) { create(:user, :trusted, :admin, name: "Beth") }
  let(:user6) { create(:user, :admin, name: "Jean", comments_count: 5) }
  let(:user7) { create(:user, :suspended, name: "Harry") }

  describe ".call" do
    context "when no arguments are given" do
      it "returns all moderators" do
        expect(described_class.call).to match_array([user, user2, user5])
      end
    end

    context "when search is set" do
      let(:options) { { search: "greg" } }

      it { is_expected.to match_array([user, user2]) }
    end

    context "when state is tag_moderator" do
      let(:options) { { state: "tag_moderator" } }

      it { is_expected.to match_array([user3]) }
    end

    context "when state is potential" do
      let(:options) { { state: "potential" } }

      it { is_expected.to match_array([user4, user6, user3]) }
    end

    context "when state does not exist" do
      let(:options) { { state: "non_existent_role" } }

      it { is_expected.to match_array([]) }
    end
  end
end
