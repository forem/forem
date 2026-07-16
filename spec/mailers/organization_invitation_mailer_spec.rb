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

    it "uses SMTP delivery when Customer.io is not configured" do
      expect(mail.message.delivery_method).not_to be_a(DeliveryMethods::CustomerIo)
    end

    context "when routed through Customer.io" do
      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "routes through the Customer.io org invitation template", :aggregate_failures do
        settings = mail.message.delivery_method.settings

        expect(settings[:transactional_message_id]).to eq("dev_org_invitation")
        expect(settings[:message_data]["org_name"]).to eq(organization.name)
        expect(settings[:message_data]["inviter_name"]).to eq(inviter.name)
        expect(settings[:message_data]["confirmation_url"]).to include(membership.invitation_token)
        expect(settings[:message_data]["community_name"]).to eq(Settings::Community.community_name)
      end
    end

    context "when routed through Customer.io with no inviter" do
      before do
        organization.organization_memberships.where.not(user_id: user.id).delete_all
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "sends a nil inviter_name" do
        settings = mail.message.delivery_method.settings

        expect(settings[:message_data]["inviter_name"]).to be_nil
      end
    end
  end
end

