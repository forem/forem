require "rails_helper"

RSpec.describe Organizations::DeleteWorker, type: :worker do
  let(:worker) { subject }

  describe "#perform" do
    let!(:org) { create(:organization) }
    let!(:user) { create(:user) }
    let(:delete) { Organizations::Delete }
    let(:mailer_class) { NotifyMailer }
    let(:mailer) { double }
    let(:message_delivery) { double }

    context "when org and user are found" do
      it "destroys the org" do
        worker.perform(org.id, user.id)
        expect(Organization.exists?(id: org.id)).to be(false)
      end

      it "calls the service" do
        allow(delete).to receive(:call)
        worker.perform(org.id, user.id)
        expect(delete).to have_received(:call).with(org)
      end

      it "touches the user" do
        allow(User).to receive(:find_by) { user }
        allow(user).to receive(:touch)
        worker.perform(org.id, user.id)
        expect(user).to have_received(:touch).with(:organization_info_updated_at)
      end

      it "busts user's cache" do
        bust_cache = EdgeCache::BustUser
        allow(bust_cache).to receive(:call)
        worker.perform(org.id, user.id)
        expect(bust_cache).to have_received(:call).with(user)
      end

      it "sends the notification" do
        allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
        expect do
          worker.perform(org.id, user.id)
        end.to change(ActionMailer::Base.deliveries, :count).by(1)
      end

      it "sends the correct notification" do
        allow(mailer_class).to receive(:with).and_return(mailer)
        allow(mailer).to receive(:organization_deleted_email).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_now)

        worker.perform(org.id, user.id)

        expect(mailer_class).to have_received(:with).with(org_name: org.name, name: user.name, email: user.email)
        expect(mailer).to have_received(:organization_deleted_email)
        expect(message_delivery).to have_received(:deliver_now)
      end

      it "creates an audit_log record" do
        expect do
          worker.perform(org.id, user.id)
        end.to change(AuditLog, :count).by(1)
      end

      it "creates a correct AuditLog record" do
        worker.perform(org.id, user.id)
        audit_log = AuditLog.find_by(category: "user.organization.delete", slug: "organization_delete",
                                     user_id: user.id)
        expect(audit_log).to be_present
        expect(audit_log.data["organization_id"]).to eq(org.id)
        expect(audit_log.data["organization_slug"]).to eq(org.slug)
      end
    end

    context "when an org or a user is not found" do
      it "doesn't fail" do
        worker.perform(-1, -1)
      end

      it "doesn't call org delete when a user was not found" do
        allow(delete).to receive(:call)
        worker.perform(org.id, -1)
        expect(delete).not_to have_received(:call)
      end

      it "doesn't call org delete when an org was not found" do
        allow(delete).to receive(:call)
        worker.perform(-1, org.id)
        expect(delete).not_to have_received(:call)
      end
    end
  end
end
