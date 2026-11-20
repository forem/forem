require "rails_helper"

RSpec.describe Notifications::UpdateJsonDataForUserWorker do
  let(:worker) { described_class.new }

  describe "#perform" do
    it "does not call the service when user is not found" do
      allow(Notifications::UpdateJsonDataForUser).to receive(:call)

      worker.perform(-1)

      expect(Notifications::UpdateJsonDataForUser).not_to have_received(:call)
    end

    it "calls the service when user is found" do
      user = create(:user)

      allow(Notifications::UpdateJsonDataForUser).to receive(:call)

      worker.perform(user.id)

      expect(Notifications::UpdateJsonDataForUser).to have_received(:call).with(user)
    end
  end
end
