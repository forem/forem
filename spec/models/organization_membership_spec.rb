require "rails_helper"

RSpec.describe OrganizationMembership, type: :model do
  describe "validations" do
    subject { build(:organization_membership) }

    let(:organization) { create(:organization) }

    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:organization_id) }
    it { is_expected.to validate_presence_of(:type_of_user) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:organization_id) }
    it { is_expected.to validate_inclusion_of(:type_of_user).in_array(OrganizationMembership::USER_TYPES) }

    it "creates member chat channel after save" do
      create(:organization_membership, type_of_user: "member", organization: organization)
      expect(ChatChannelMembership.last.role).to eq("member")
      expect(ChatChannelMembership.last.chat_channel.channel_name).to eq("@#{organization.slug} private group chat")
    end

    it "adds user to existing org chat channel after save" do
      chat_channel = create(:chat_channel, channel_name: "@#{organization.slug} private group chat")
      organization_membership = create(:organization_membership, type_of_user: "member", organization: organization)
      expect(chat_channel.active_users).to include(organization_membership.user)
    end

    it "updates chat channel membership if org membership is updated" do
      organization_membership = create(:organization_membership, type_of_user: "member", organization: organization)
      expect(ChatChannelMembership.last.role).to eq("member")
      organization_membership.update(type_of_user: "admin")
      expect(ChatChannelMembership.last.role).to eq("mod")
    end
  end
end
