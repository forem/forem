require "rails_helper"

RSpec.describe Admin::GDPRDeleteRequestsQuery, type: :query do
  subject { described_class.call(search: search) }

  let!(:gdpr_delete_request_1) do
    create(:gdpr_delete_request, username: "delete_1", email: "delete_1@test.com", name: "Alice Smith")
  end
  let!(:gdpr_delete_request_2) do
    create(:gdpr_delete_request, username: "delete_2", email: "delete_2@test.com", name: "Bob Jones")
  end
  let!(:gdpr_delete_request_3) do
    create(:gdpr_delete_request, username: "delete_3", email: "delete_3@test.com", name: nil)
  end
  let!(:gdpr_delete_request_11) do
    create(:gdpr_delete_request, username: "delete_11", email: "delete_11@test.com", name: "Alice Johnson")
  end

  describe ".call" do
    context "when no arguments are given" do
      it "returns all users" do
        # rubocop:disable Layout/LineLength
        expect(described_class.call).to match_array([gdpr_delete_request_1, gdpr_delete_request_2, gdpr_delete_request_3, gdpr_delete_request_11])
        # rubocop:enable Layout/LineLength
      end
    end

    context "when searching for a user by username" do
      let(:search) { "delete_2" }

      it { is_expected.to match_array([gdpr_delete_request_2]) }
    end

    context "when searching for a user by email" do
      let(:search) { "delete_1@test.com" }

      it { is_expected.to match_array([gdpr_delete_request_1]) }
    end

    context "when searching for ambiguous terms that matches multiple users" do
      let(:search) { "delete_1" }

      it { is_expected.to match_array([gdpr_delete_request_1, gdpr_delete_request_11]) }
    end

    context "when searching for ambiguous terms that matches both emails and usernames" do
      let(:search) { "delete" }

      # rubocop:disable Layout/LineLength
      it { is_expected.to match_array([gdpr_delete_request_1, gdpr_delete_request_2, gdpr_delete_request_3, gdpr_delete_request_11]) }
      # rubocop:enable Layout/LineLength
    end

    context "when passed a non-existent email or username" do
      let(:search) { "non_existent_email" }

      it { is_expected.to match_array([]) }
    end

    context "when searching for a user by name" do
      let(:search) { "Alice Smith" }

      it { is_expected.to contain_exactly(gdpr_delete_request_1) }
    end

    context "when searching for a partial name matching multiple users" do
      let(:search) { "Alice" }

      it { is_expected.to contain_exactly(gdpr_delete_request_1, gdpr_delete_request_11) }
    end
  end
end
