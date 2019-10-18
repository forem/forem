require "rails_helper"

RSpec.describe Users::SelfDeleteJob, type: :job do
  include_examples "#enqueues_job", "users_self_delete", 1

  describe "#perform_now" do
    let(:user) { create(:user) }
    let(:delete) { double }

    before do
      allow(delete).to receive(:call)
    end

    context "when user is found" do
      it "calls the service when a user is found" do
        described_class.perform_now(user.id, delete)
        expect(delete).to have_received(:call).with(user)
      end

      it "sends the notification" do
        expect do
          described_class.perform_now(user.id, delete)
        end.to change(ActionMailer::Base.deliveries, :count).by(1)
      end

      it "sends the correct notification" do
        allow(NotifyMailer).to receive(:account_deleted_email).and_call_original
        described_class.perform_now(user.id, delete)
        expect(NotifyMailer).to have_received(:account_deleted_email).with(user)
      end
    end

    context "when user is not found" do
      it "doesn't fail" do
        described_class.perform_now(-1, delete)
      end

      it "doesn't send the notification" do
        expect do
          described_class.perform_now(-1, delete)
        end.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end
  end
end
