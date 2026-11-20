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
        expect(described_class.call).to contain_exactly(user, user2, user5)
      end
    end

    context "when search is set" do
      let(:options) { { search: "greg" } }

      it { is_expected.to contain_exactly(user, user2) }
    end

    context "when state is tag_moderator" do
      let(:options) { { state: "tag_moderator" } }

      it { is_expected.to contain_exactly(user3) }
    end

    context "when state is potential" do
      let(:options) { { state: "potential" } }

      it { is_expected.to contain_exactly(user4, user6, user3) }

      it "uses a correlated NOT EXISTS anti-join and skips Role lookup for 'potential'" do
        queries = []
        subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
          queries << payload[:sql] unless payload[:name] == "SCHEMA"
        end

        sql = described_class.call(options: options).to_sql
        ActiveSupport::Notifications.unsubscribe(subscriber)

        expect(sql).to include("NOT EXISTS (SELECT 1 FROM users_roles WHERE users_roles.user_id = users.id")
        expect(queries.none? { |q| q.include?("potential") }).to be(true)
      end
    end

    context "when state does not exist" do
      let(:options) { { state: "non_existent_role" } }

      it { is_expected.to match_array([]) }
    end
  end
end
