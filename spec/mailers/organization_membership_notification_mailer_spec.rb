require "rails_helper"

RSpec.describe OrganizationMembershipNotificationMailer, type: :mailer do
  let(:organization) { create(:organization, fully_trusted: true) }
  let(:user) { create(:user) }
  let(:inviter) { create(:user) }
  let(:membership) do
    create(:organization_membership, user: user, organization: organization, type_of_user: "member")
  end

  before do
    create(:organization_membership, user: inviter, organization: organization, type_of_user: "admin")
  end

  describe "#member_added_email" do
    let(:mail) do
      OrganizationMembershipNotificationMailer.with(membership_id: membership.id).member_added_email
    end

    it "renders the headers" do
      expect(mail.subject).to include(organization.name)
      expect(mail.to).to eq([user.email])
    end

    it "includes organization information" do
      expect(mail.body.encoded).to include(organization.name)
    end

    it "includes organization URL" do
      expect(mail.body.encoded).to include(organization.slug)
    end

    it "includes inviter information when available" do
      expect(mail.body.encoded).to include(inviter.name)
    end

    it "includes explanation of organizations" do
      expect(mail.body.encoded).to include("Organizations")
    end

    it "does not include confirmation link" do
      expect(mail.body.encoded).not_to include("confirm")
    end
  end
end

