require "rails_helper"

RSpec.describe Users::DeleteJob, type: :job do
  include_examples "#enqueues_job", "users_delete", 1

  describe "#perform_now" do
    let(:user) { create(:user) }
    let(:delete) { double }

    before do
      allow(delete).to receive(:call)
    end

    it "calls the service when a user is found" do
      described_class.perform_now(user.id, delete)
      expect(delete).to have_received(:call).with(user)
    end

    it "doesn't fail when a user is not found" do
      described_class.perform_now(-1, delete)
    end
  end
end
