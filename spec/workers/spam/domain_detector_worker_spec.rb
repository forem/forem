require "rails_helper"

RSpec.describe Spam::DomainDetectorWorker, type: :worker do
  describe "#perform" do
    it "runs domain detection for the user" do
      user = create(:user)
      detector = instance_double(Spam::DomainDetector, check_and_block_domain!: false)
      allow(Spam::DomainDetector).to receive(:new).with(user).and_return(detector)

      described_class.new.perform(user.id)

      expect(detector).to have_received(:check_and_block_domain!)
    end

    it "returns early when the user does not exist" do
      allow(Spam::DomainDetector).to receive(:new)

      described_class.new.perform(999_999)

      expect(Spam::DomainDetector).not_to have_received(:new)
    end
  end
end
