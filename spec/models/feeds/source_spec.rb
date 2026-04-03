require "rails_helper"

RSpec.describe Feeds::Source do
  let(:user) { create(:user) }

  before do
    allow(Feeds::ValidateUrl).to receive(:call).and_return(true)
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:organization).optional }
    it { is_expected.to belong_to(:author).optional }
    it { is_expected.to have_many(:import_logs).dependent(:nullify) }
  end

  describe "enums" do
    it {
      is_expected.to define_enum_for(:status)
        .with_values(healthy: 0, degraded: 1, failing: 2, inactive: 3)
        .with_prefix(:feed)
    }
  end

  describe "validations" do
    it "requires feed_url" do
      source = build(:feed_source, feed_url: nil)
      expect(source).not_to be_valid
      expect(source.errors[:feed_url]).to include("can't be blank")
    end

    it "enforces feed_url uniqueness per user" do
      create(:feed_source, user: user, feed_url: "https://example.com/feed.xml")
      duplicate = build(:feed_source, user: user, feed_url: "https://example.com/feed.xml")
      expect(duplicate).not_to be_valid
    end

    it "allows same URL for different users" do
      create(:feed_source, feed_url: "https://example.com/feed.xml")
      other = build(:feed_source, feed_url: "https://example.com/feed.xml")
      expect(other).to be_valid
    end

    it "validates name length" do
      source = build(:feed_source, name: "a" * 101)
      expect(source).not_to be_valid
    end
  end

  describe "organization validation" do
    let(:org) { create(:organization) }

    it "requires user to be a member of the organization" do
      source = build(:feed_source, user: user, organization: org)
      expect(source).not_to be_valid
      expect(source.errors[:organization]).to be_present
    end

    it "allows organization when user is a member" do
      create(:organization_membership, user: user, organization: org, type_of_user: "member")
      source = build(:feed_source, user: user, organization: org)
      expect(source).to be_valid
    end
  end

  describe "author validation" do
    let(:org) { create(:organization) }
    let(:author) { create(:user) }

    it "allows self as author without org" do
      source = build(:feed_source, user: user, author_user_id: user.id)
      expect(source).to be_valid
    end

    it "rejects other author without org" do
      source = build(:feed_source, user: user, author_user_id: author.id)
      expect(source).not_to be_valid
      expect(source.errors[:author_user_id]).to include("can only be set when an organization is selected")
    end

    it "rejects other author when user is not org admin" do
      create(:organization_membership, user: user, organization: org, type_of_user: "member")
      create(:organization_membership, user: author, organization: org, type_of_user: "member")
      source = build(:feed_source, user: user, organization: org, author_user_id: author.id)
      expect(source).not_to be_valid
      expect(source.errors[:author_user_id]).to include("you must be an org admin to assign another author")
    end

    it "allows other author when user is org admin and author is org member" do
      create(:organization_membership, user: user, organization: org, type_of_user: "admin")
      create(:organization_membership, user: author, organization: org, type_of_user: "member")
      source = build(:feed_source, user: user, organization: org, author_user_id: author.id)
      expect(source).to be_valid
    end

    it "rejects author who is not an org member" do
      create(:organization_membership, user: user, organization: org, type_of_user: "admin")
      source = build(:feed_source, user: user, organization: org, author_user_id: author.id)
      expect(source).not_to be_valid
      expect(source.errors[:author_user_id]).to include("must be a member of the selected organization")
    end
  end

  describe "#effective_author" do
    it "returns author when set" do
      source = build(:feed_source, :with_author)
      expect(source.effective_author).to eq(source.author)
    end

    it "falls back to user when no author set" do
      source = build(:feed_source, user: user)
      expect(source.effective_author).to eq(user)
    end
  end

  describe "#update_health!" do
    let(:source) { create(:feed_source, user: user) }

    it "resets to healthy on success" do
      source.update_columns(status: 1, consecutive_failures: 2) # degraded
      source.update_health!(success: true)
      expect(source.reload).to be_feed_healthy
      expect(source.consecutive_failures).to eq(0)
    end

    it "transitions to degraded on first failure" do
      source.update_health!(success: false)
      expect(source.reload).to be_feed_degraded
      expect(source.consecutive_failures).to eq(1)
    end

    it "transitions to failing after 3 consecutive failures" do
      source.update_columns(consecutive_failures: 2, status: 1) # degraded with 2 failures
      source.update_health!(success: false)
      expect(source.reload).to be_feed_failing
      expect(source.consecutive_failures).to eq(3)
    end
  end

  describe "scopes" do
    describe ".active" do
      it "excludes inactive sources" do
        active = create(:feed_source, user: user)
        create(:feed_source, :inactive, user: create(:user))
        expect(described_class.active).to include(active)
        expect(described_class.active.count).to eq(1)
      end
    end
  end

  describe "factory" do
    it "creates a valid source" do
      source = create(:feed_source, user: user)
      expect(source).to be_valid
      expect(source).to be_feed_healthy
    end

    it "creates a valid source with organization" do
      source = create(:feed_source, :with_organization)
      expect(source).to be_valid
      expect(source.organization).to be_present
    end

    it "creates a valid source with author" do
      source = create(:feed_source, :with_author)
      expect(source).to be_valid
      expect(source.author).to be_present
    end
  end
end
