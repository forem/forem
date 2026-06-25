require "rails_helper"

RSpec.describe Images::ProfileSocialImageWorker, type: :worker do
  let(:user) { create(:user) }

  describe "#perform" do
    it "calls Images::GenerateProfileSocialImageMagickally" do
      allow(Images::GenerateProfileSocialImageMagickally).to receive(:call)
      described_class.new.perform(user.id, "User")
      expect(Images::GenerateProfileSocialImageMagickally).to have_received(:call).with(user)
    end
  end
end
