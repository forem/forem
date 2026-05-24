require "rails_helper"

RSpec.describe OrganizationInvitationMailer, type: :mailer do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:inviter) { create(:user) }
  let(:membership) do
    create(:organization_membership, user: user, organization: organization, type_of_user: "pending")
  end

  before do
    create(:organization_membership, user: inviter, organization: organization, type_of_user: "admin")
  end

  describe "#invitation_email" do
    let(:mail) do
      OrganizationInvitationMailer.with(membership_id: membership.id).invitation_email
    end

    it "renders the headers" do
      expect(mail.subject).to include(organization.name)
      expect(mail.to).to eq([user.email])
    end

    it "includes organization information" do
      expect(mail.body.encoded).to include(organization.name)
    end

    it "includes confirmation URL" do
      expect(mail.body.encoded).to include(membership.invitation_token)
    end

    it "includes inviter information when available" do
      expect(mail.body.encoded).to include(inviter.name)
    end

    it "includes explanation of organizations" do
      expect(mail.body.encoded).to include("Organizations")
    end
  end
end

