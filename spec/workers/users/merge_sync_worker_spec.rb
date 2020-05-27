require "rails_helper"

RSpec.describe Users::MergeSyncWorker, type: :worker do
  describe "#perform" do
    let(:user) { create(:user) }
    let(:worker) { subject }

    xit "resaves all user content" do
      allow(worker).to receive(:resave_content)
      worker.perform(user.id)
      expect(worker).to have_received(:resave_content).exactly(4).times
    end
  end
end
