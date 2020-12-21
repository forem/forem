require "rails_helper"

RSpec.describe Users::DeleteWorker, type: :worker do
  let(:worker) { subject }
  let(:mailer_class) { NotifyMailer }
  let(:mailer) { double }
  let(:message_delivery) { double }

  describe "#perform" do
    let!(:user) { create(:user) }
    let(:delete) { Users::Delete }

    context "when user is found" do
      it "deletes the user correctly" do
        worker.perform(user.id)

        expect(User.exists?(id: user.id)).to be(false)
      end

      it "calls the service when a user is found" do
        allow(delete).to receive(:call)
        worker.perform(user.id)
        expect(delete).to have_received(:call).with(user)
      end

      it "sends the notification" do
        expect do
          worker.perform(user.id)
        end.to change(ActionMailer::Base.deliveries, :count).by(1)
      end

      it "doesn't send a notification for admin triggered deletion" do
        expect do
          worker.perform(user.id, true)
        end.not_to change(ActionMailer::Base.deliveries, :count)
      end

      it "sends the correct notification" do
        allow(mailer_class).to receive(:with).and_return(mailer)
        allow(mailer).to receive(:account_deleted_email).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_now)

        worker.perform(user.id)

        expect(mailer_class).to have_received(:with).with(name: user.name, email: user.email)
        expect(mailer).to have_received(:account_deleted_email)
        expect(message_delivery).to have_received(:deliver_now)
      end

      it "creates a gdpr-delete record" do
        expect do
          worker.perform(user.id, true)
        end.to change(Users::GdprDeleteRequest, :count).by(1)
      end
    end

    context "when user is not found" do
      it "doesn't fail" do
        worker.perform(-1)
      end

      it "doesn't send the notification" do
        expect do
          worker.perform(-1)
        end.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end
  end
end
