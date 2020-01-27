require "rails_helper"

RSpec.describe Users::EstimateDefaultLanguageWorker, type: :worker do
  describe "#perform" do
    let(:user) { create(:user) }
    let(:service) { Users::EstimateDefaultLanguage }
    let(:worker) { subject }

    before { allow(service).to receive(:call) }

    it "calls a service" do
      worker.perform(user.id)
      expect(service).to have_received(:call).with(user).once
    end

    it "doesn't to anything for a non-existent user" do
      worker.perform(User.maximum(:id).to_i + 1)
      expect(service).not_to have_received(:call)
    end
  end
end
