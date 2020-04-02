require "rails_helper"

RSpec.describe Internal::ModeratorsQuery, type: :query do
  subject { described_class.call(options: options) }

  let_it_be_readonly(:user)  { create(:user, :trusted, name: "Greg") }
  let_it_be_readonly(:user2) { create(:user, :trusted, name: "Gregory") }
  let_it_be_readonly(:user3) { create(:user, :tag_moderator, name: "Paul", comments_count: 4) }
  let_it_be_readonly(:user4) { create(:user, :admin, name: "Susi", comments_count: 10) }
  let_it_be_readonly(:user5) { create(:user, :trusted, :admin, name: "Beth") }
  let_it_be_readonly(:user6) { create(:user, :admin, name: "Jean", comments_count: 5) }

  describe ".call" do
    context "when no arguments are given" do
      it "returns all moderators" do
        expect(described_class.call).to eq([user, user2, user5])
      end
    end

    context "when search is set" do
      let(:options) { { search: "greg" } }

      it { is_expected.to eq([user, user2]) }
    end

    context "when state is tag_moderator" do
      let(:options) { { state: "tag_moderator" } }

      it { is_expected.to eq([user3]) }
    end

    context "when state is potential" do
      let(:options) { { state: "potential" } }

      it { is_expected.to eq([user4, user6, user3]) }
    end

    context "when state does not exist" do
      let(:options) { { state: "non_existent_role" } }

      it { within_block_is_expected.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end
end
