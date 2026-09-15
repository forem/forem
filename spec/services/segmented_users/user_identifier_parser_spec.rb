require "rails_helper"

RSpec.describe SegmentedUsers::UserIdentifierParser do
  let!(:user1) { create(:user, :with_newsletters, username: "alice", email: "alice@example.com") }
  let!(:user2) { create(:user, :with_newsletters, username: "bob", email: "bob@example.com") }
  let!(:user3) { create(:user, :with_newsletters, username: "charlie", email: "charlie@example.com") }
  let!(:suspended_user) { create(:user, :suspended, username: "spammer", email: "spammer@example.com") }

  describe ".call" do
    it "resolves users by username (with and without @)" do
      result = described_class.call(raw_input: "@alice, bob")
      expect(result.valid_users).to contain_exactly(user1, user2)
      expect(result.unresolved_identifiers).to be_empty
    end

    it "resolves users by email address" do
      result = described_class.call(raw_input: "alice@example.com, charlie@example.com")
      expect(result.valid_users).to contain_exactly(user1, user3)
      expect(result.unresolved_identifiers).to be_empty
    end

    it "resolves users by ID" do
      result = described_class.call(raw_input: "#{user1.id}, #{user2.id}")
      expect(result.valid_users).to contain_exactly(user1, user2)
      expect(result.unresolved_identifiers).to be_empty
    end

    it "handles mixed inputs with commas, newlines, and semicolons" do
      raw = "#{user1.id}\n@bob; charlie@example.com"
      result = described_class.call(raw_input: raw)
      expect(result.valid_users).to contain_exactly(user1, user2, user3)
      expect(result.unresolved_identifiers).to be_empty
    end

    it "reports unresolved identifiers that do not match any user" do
      result = described_class.call(raw_input: "alice, non_existent_user, unknown@example.com, 999999")
      expect(result.valid_users).to contain_exactly(user1)
      expect(result.unresolved_identifiers).to contain_exactly("non_existent_user", "unknown@example.com", "999999")
    end

    it "identifies and flags ineligible users" do
      result = described_class.call(raw_input: "alice, spammer")
      expect(result.valid_users).to contain_exactly(user1, suspended_user)
      expect(result.ineligible_users).to contain_exactly(suspended_user)
      expect(result.eligible_user_ids).to contain_exactly(user1.id)
    end

    it "deduplicates repeated identifiers" do
      result = described_class.call(raw_input: "alice, @alice, alice@example.com, #{user1.id}")
      expect(result.valid_users).to eq([user1])
      expect(result.valid_users.size).to eq(1)
    end

    it "resolves users from an active UserQuery" do
      query_creator = create(:user)
      user_query = create(
        :user_query,
        name: "Active Alice Query",
        created_by: query_creator,
        query: "SELECT id FROM users WHERE username = 'alice'",
      )
      result = described_class.call(user_query: user_query)
      expect(result.valid_users).to contain_exactly(user1)
    end

    it "returns an empty result for empty or blank input" do
      result = described_class.call(raw_input: "   \n\t  ")
      expect(result.valid_users).to be_empty
      expect(result.unresolved_identifiers).to be_empty
      expect(result.success?).to be(false)
    end
  end
end
