require "rails_helper"

RSpec.describe Users::EstimateDefaultLanguageJob, type: :job do
  include_examples "#enqueues_job", "users_estimate_language", 2

  describe "#perform_now" do
    let(:user) { create(:user) }
    let(:service) { double }

    before { allow(service).to receive(:call) }

    it "calls a service" do
      described_class.perform_now(user.id, service)
      expect(service).to have_received(:call).with(user).once
    end

    it "doesn't to anything for a non-existent user" do
      described_class.perform_now(User.maximum(:id).to_i + 1, service)
      expect(service).not_to have_received(:call)
    end
  end
end
