require "rails_helper"

# rubocop:disable RSpec/PredicateMatcher
RSpec.describe Authorizer, type: :policy do
  subject(:authorizer) { described_class.for(user: user) }

  let(:authorizer_mod_role) { described_class.for(user: mod_user) }
  let(:user) { create(:user) }
  let(:mod_user) { create(:user, :super_moderator) }

  describe "#any_admin?" do
    it "queries the user's roles" do
      # I want to test `expect(authorizer.admin?)` but our rubocop
      # version squaks.
      expect(authorizer.admin?).to be_falsey
    end
  end

  describe "#super_moderator?" do
    it "queries the user's roles" do
      expect(authorizer.super_moderator?).to be_falsey
      expect(authorizer_mod_role.super_moderator?).to be_truthy
    end
  end

  describe "#administrative_access_to?" do
    subject(:method_call) { authorizer.administrative_access_to?(resource: resource) }

    let(:resource) { nil }

    context "when not an admin or super admin and not given a resource" do
      let(:user) { build(:user) }

      it { is_expected.to be_falsey }
    end

    context "when an admin and not given a resource" do
      let(:user) { build(:user, :admin) }

      it { is_expected.to be_truthy }
    end

    context "when a super_admin and not given a resource" do
      let(:user) { build(:user, :super_admin) }

      it { is_expected.to be_truthy }
    end

    context "when given a resource and the user is assigned singular administration" do
      let(:resource) { Article }

      before do
        user.add_role(:single_resource_admin, resource)
      end

      it { is_expected.to be_truthy }
    end

    context "when given a resource and the user is assigned singular administration to another" do
      let(:resource) { Article }

      before do
        user.add_role(:single_resource_admin, Comment)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe "#trusted?" do
    # We don't need a saved user.  Let's not require that.
    let(:user) { instance_double(User, id: 123) }

    it "memoizes the result from rolify" do
      allow(Rails.cache)
        .to receive(:fetch)
        .with("user-#{user.id}/has_trusted_role", expires_in: 200.hours)
        .and_return(false)
        .once

      2.times { authorizer.trusted? }
    end
  end

  describe "#community_leader?" do
    it "is false for a regular user" do
      expect(authorizer.community_leader?).to be_falsey
    end

    it "is true for a level 1 leader" do
      leader = described_class.for(user: create(:user, :community_leader_level_1))
      expect(leader.community_leader?).to be_truthy
    end

    it "is true for a level 2 leader" do
      leader = described_class.for(user: create(:user, :community_leader_level_2))
      expect(leader.community_leader?).to be_truthy
    end
  end

  describe "#tag_moderator?" do
    let(:tag) { create(:tag) }

    context "when the user is a regular user" do
      it "is false without a tag" do
        expect(authorizer.tag_moderator?).to be_falsey
      end

      it "is false for a specific tag" do
        expect(authorizer.tag_moderator?(tag: tag)).to be_falsey
      end
    end

    context "when the user moderates a specific tag" do
      before { user.add_role(:tag_moderator, tag) }

      it "is true without a tag (moderates at least one tag)" do
        expect(authorizer.tag_moderator?).to be_truthy
      end

      it "is true for the tag they moderate" do
        expect(authorizer.tag_moderator?(tag: tag)).to be_truthy
      end

      it "is false for a tag they do not moderate" do
        expect(authorizer.tag_moderator?(tag: create(:tag))).to be_falsey
      end
    end

    context "when the user is a community leader" do
      let(:user) { create(:user, :community_leader_level_1) }

      it "is true without a tag (global capability)" do
        expect(authorizer.tag_moderator?).to be_truthy
      end

      it "is true for any specific tag" do
        expect(authorizer.tag_moderator?(tag: tag)).to be_truthy
      end
    end
  end

  describe "with preloaded roles" do
    let(:tag) { create(:tag) }
    let(:subforem) { create(:subforem) }

    before do
      user.add_role(:admin)
      user.add_role(:tag_moderator, tag)
      user.add_role(:subforem_moderator, subforem)
      user.reload
      user.roles.load
    end

    it "answers global and resource role questions without more role queries" do
      role_queries = []
      subscriber = lambda do |_name, _started, _finished, _unique_id, payload|
        role_queries << payload[:sql] if payload[:sql].include?('FROM "roles"')
      end

      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
        expect(authorizer.any_admin?).to be(true)
        expect(authorizer.tag_moderator?).to be(true)
        expect(authorizer.tag_moderator?(tag: tag)).to be(true)
        expect(authorizer.subforem_moderator?).to be(true)
        expect(authorizer.subforem_moderator?(subforem: subforem)).to be(true)
      end

      expect(role_queries).to be_empty
    end
  end

  describe "#vomited_on?" do
    subject(:method_call) { authorizer.vomited_on? }

    # I included this test because I had mis-copied something and the
    # system broke.  This test is my "penance" for pushing up broken
    # code.
    it { is_expected.not_to be_nil }
  end
end
# rubocop:enable RSpec/PredicateMatcher
