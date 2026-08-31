require "rails_helper"

RSpec.describe Organizations::BulkAddUsers do
  let(:organization) { create(:organization) }
  let(:user1) { create(:user, username: "user_one") }
  let(:user2) { create(:user, username: "user_two") }
  let(:user3) { create(:user, username: "user_three") }

  describe ".parse_usernames" do
    it "handles comma-separated usernames with or without @ and spaces" do
      input = " @user_one,  user_two , @user_three "
      expect(described_class.parse_usernames(input)).to eq(%w[user_one user_two user_three])
    end

    it "handles newline-separated usernames" do
      input = "@user_one\nuser_two\r\n@user_three"
      expect(described_class.parse_usernames(input)).to eq(%w[user_one user_two user_three])
    end

    it "handles downcasing and deduplication" do
      input = "User_One, @USER_ONE, user_two"
      expect(described_class.parse_usernames(input)).to eq(%w[user_one user_two])
    end

    it "handles empty or whitespace-only inputs" do
      expect(described_class.parse_usernames("")).to eq([])
      expect(described_class.parse_usernames("   ")).to eq([])
      expect(described_class.parse_usernames(", , ,")).to eq([])
      expect(described_class.parse_usernames(nil)).to eq([])
    end
  end

  describe "#call" do
    context "when input is empty or invalid" do
      it "returns empty_input result" do
        result = described_class.call(organization: organization, usernames: "")
        expect(result.empty_input?).to be true
        expect(result.added_users).to be_empty
        expect(result.already_members).to be_empty
        expect(result.not_found).to be_empty
      end
    end

    context "when adding new valid users" do
      it "adds users as members by default", :aggregate_failures do
        input = "@#{user1.username}, #{user2.username}"
        result = described_class.call(organization: organization, usernames: input)

        expect(result.empty_input?).to be false
        expect(result.added_users).to contain_exactly(user1.username, user2.username)
        expect(result.already_members).to be_empty
        expect(result.not_found).to be_empty

        membership1 = organization.organization_memberships.find_by(user_id: user1.id)
        membership2 = organization.organization_memberships.find_by(user_id: user2.id)
        expect(membership1.type_of_user).to eq("member")
        expect(membership2.type_of_user).to eq("member")
      end

      it "adds users as admins when role is specified", :aggregate_failures do
        input = user1.username
        result = described_class.call(organization: organization, usernames: input, role: "admin")

        expect(result.added_users).to eq([user1.username])
        membership = organization.organization_memberships.find_by(user_id: user1.id)
        expect(membership.type_of_user).to eq("admin")
      end
    end

    context "when users do not exist" do
      it "records not_found usernames", :aggregate_failures do
        input = "@#{user1.username}, nonexistent_user_xyz"
        result = described_class.call(organization: organization, usernames: input)

        expect(result.added_users).to eq([user1.username])
        expect(result.not_found).to eq(["nonexistent_user_xyz"])
        expect(result.already_members).to be_empty
      end
    end

    context "when users are already members of the organization" do
      before do
        create(:organization_membership, organization: organization, user: user1, type_of_user: "member")
      end

      it "records already_members and does not create duplicate memberships", :aggregate_failures do
        input = "@#{user1.username}, #{user2.username}"
        expect do
          result = described_class.call(organization: organization, usernames: input)
          expect(result.added_users).to eq([user2.username])
          expect(result.already_members).to eq([user1.username])
        end.to change { organization.organization_memberships.count }.by(1)
      end
    end

    context "when handling mixed valid, existing, and non-existent usernames" do
      before do
        create(:organization_membership, organization: organization, user: user1, type_of_user: "member")
      end

      it "processes each category accurately", :aggregate_failures do
        input = "@#{user1.username}, #{user2.username}, unknown_dev, @#{user3.username}"
        result = described_class.call(organization: organization, usernames: input)

        expect(result.added_users).to contain_exactly(user2.username, user3.username)
        expect(result.already_members).to eq([user1.username])
        expect(result.not_found).to eq(["unknown_dev"])
      end
    end

    context "when a race condition raises RecordNotUnique on membership save" do
      it "handles the error gracefully and marks the user as already member", :aggregate_failures do
        allow_any_instance_of(OrganizationMembership).to receive(:save) # rubocop:disable RSpec/AnyInstance
          .and_raise(ActiveRecord::RecordNotUnique)

        result = described_class.call(organization: organization, usernames: user1.username)
        expect(result.added_users).to be_empty
        expect(result.already_members).to eq([user1.username])
      end
    end
  end
end
