require "rails_helper"

RSpec.describe Users::ResolveSpamReportsWorker, type: :worker do
  describe "#perform" do
    let(:user) { create(:user) }
    let(:worker) { subject }

    it "calls spam reports resolver" do
      allow(Users::ResolveSpamReports).to receive(:call).with(user)

      worker.perform(user.id)
      expect(Users::ResolveSpamReports).to have_received(:call).with(user)
    end

    it "doesn't fail with invalid url" do
      worker.perform(-1)
    end
  end
end
