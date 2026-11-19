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

  describe "#sub_permission?" do
    let(:user) { create(:user) }
    let(:clauses) { SubPermissions.clauses_for("Billboard") }

    def restrict(user, allow, resource_type: "Billboard")
      SubPermissions.update_grant(user: user, resource_type: resource_type,
                                  sub_permissions: SubPermissions.build(allow: allow))
    end

    def grant_rows(user)
      UserRole.where(user_id: user.id)
    end

    def allowed_clauses(user)
      authorizer = described_class.for(user: user.reload)
      clauses.select { |clause| authorizer.sub_permission?(resource: Billboard, clause: clause) }
    end

    it "raises on a clause that is not registered, even for admins", :aggregate_failures do
      admin = create(:user, :admin)

      expect { authorizer.sub_permission?(resource: Billboard, clause: "aprove") }.to raise_error(ArgumentError)
      expect { described_class.for(user: admin).sub_permission?(resource: Billboard, clause: "aprove") }
        .to raise_error(ArgumentError)
      expect { authorizer.sub_permission?(resource: Article, clause: "approve") }.to raise_error(ArgumentError)
    end

    it "denies every clause to a user without a grant" do
      expect(allowed_clauses(user)).to be_empty
    end

    it "allows every clause to an unrestricted grant, as before sub-permissions existed" do
      user.add_role(:single_resource_admin, Billboard)

      expect(allowed_clauses(user)).to eq(clauses)
    end

    it "allows only the listed clauses to a restricted grant", :aggregate_failures do
      user.add_role(:single_resource_admin, Billboard)

      restrict(user, [])
      expect(allowed_clauses(user)).to be_empty

      restrict(user, %w[publish])
      expect(allowed_clauses(user)).to eq(%w[publish])

      restrict(user, clauses)
      expect(allowed_clauses(user)).to eq(clauses)
    end

    it "allows every clause to admins and super admins, even with a restricted grant", :aggregate_failures do
      %i[admin super_admin].each do |role|
        privileged = create(:user, role)
        privileged.add_role(:single_resource_admin, Billboard)
        restrict(privileged, [])

        expect(allowed_clauses(privileged)).to eq(clauses)
      end
    end

    it "does not treat tech admins or other roles as Billboard admins" do
      user.add_role(:tech_admin)
      user.add_role(:single_resource_admin, Article)

      expect(allowed_clauses(user)).to be_empty
    end

    it "honors a global single_resource_admin grant the way rolify does" do
      user.add_role(:single_resource_admin)

      expect(allowed_clauses(user)).to eq(clauses)
    end

    it "combines grants, so an unrestricted grant outweighs a restricted one" do
      user.add_role(:single_resource_admin, Billboard)
      restrict(user, [])
      user.add_role(:single_resource_admin)

      expect(allowed_clauses(user)).to eq(clauses)
    end

    it "checks a record against grants on its class and on the record itself", :aggregate_failures do
      billboard = create(:billboard)
      other_billboard = create(:billboard)
      user.add_role(:single_resource_admin, billboard)

      expect(described_class.for(user: user.reload).sub_permission?(resource: billboard, clause: "approve")).to be(true)
      expect(described_class.for(user: user).sub_permission?(resource: other_billboard, clause: "approve")).to be(false)
      expect(described_class.for(user: user).sub_permission?(resource: Billboard, clause: "approve")).to be(false)
    end

    it "does not let another user's restriction or grant leak", :aggregate_failures do
      other = create(:user)
      other.add_role(:single_resource_admin, Billboard)
      user.add_role(:single_resource_admin, Billboard)
      restrict(user, [])

      expect(allowed_clauses(user)).to be_empty
      expect(allowed_clauses(other)).to eq(clauses)
    end

    context "when the stored configuration is unreadable" do
      before { user.add_role(:single_resource_admin, Billboard) }

      {
        "a JSON null" => "'null'::jsonb",
        "a future version" => %q('{"version": 2, "allow": ["approve", "publish", "modify_approved"]}'::jsonb),
        "an unknown key" => %q('{"version": 1, "allow": ["approve"], "deny": []}'::jsonb),
        "a string" => %q('"approve"'::jsonb),
        "an array" => %q('["approve"]'::jsonb)
      }.each do |description, sql|
        it "fails closed with #{description}" do
          grant_rows(user).update_all("sub_permissions = #{sql}")

          expect(allowed_clauses(user)).to be_empty
        end
      end
    end

    it "is delegated from User" do
      user.add_role(:single_resource_admin, Billboard)

      expect(user.reload.sub_permission?(resource: Billboard, clause: "approve")).to be(true)
    end
  end
end
# rubocop:enable RSpec/PredicateMatcher
