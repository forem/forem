require "rails_helper"

RSpec.describe Users::DeleteWorker, type: :worker do
  describe "#perform" do
    let(:user) { create(:user) }
    let(:delete) { Users::Delete }
    let(:worker) { subject }

    before do
      allow(delete).to receive(:call)
    end

    context "when user is found" do
      it "calls the service when a user is found" do
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
        allow(NotifyMailer).to receive(:account_deleted_email).and_call_original
        worker.perform(user.id)
        expect(NotifyMailer).to have_received(:account_deleted_email).with(user)
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
