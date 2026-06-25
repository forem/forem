require "rails_helper"

RSpec.describe Images::GenerateProfileSocialImageMagickally, type: :model do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:background_image) { instance_double(MiniMagick::Image) }

  describe ".call" do
    context "when resource is a User" do
      let(:generator) { described_class.new(user) }

      before do
        allow(described_class).to receive(:new).and_return(generator)
        allow(generator).to receive(:read_files)
        allow(generator).to receive(:generate_magickally).and_return("https://www.example.com/user_social.png")
      end

      it "updates user profile social image" do
        described_class.call(user)
        expect(user.profile.reload.social_image).to eq("https://www.example.com/user_social.png")
      end

      it "triggers Users::BustProfileDetailsCacheWorker" do
        allow(Users::BustProfileDetailsCacheWorker).to receive(:perform_async)
        described_class.call(user)
        expect(Users::BustProfileDetailsCacheWorker).to have_received(:perform_async).with(user.id)
      end

      context "when an external fetch fails with an HTTP error" do
        it "logs a warning and does not alert Honeybadger" do
          allow(generator).to receive(:read_files).and_raise(OpenURI::HTTPError.new("504 Gateway Timeout", StringIO.new))
          allow(Rails.logger).to receive(:warn)
          allow(Honeybadger).to receive(:notify)

          described_class.call(user)

          expect(Rails.logger).to have_received(:warn).with(/Image fetch failed:/)
          expect(Honeybadger).not_to have_received(:notify)
        end
      end
    end

    context "when resource is an Organization" do
      let(:generator) { described_class.new(organization) }

      before do
        allow(described_class).to receive(:new).and_return(generator)
        allow(generator).to receive(:read_files)
        allow(generator).to receive(:generate_magickally).and_return("https://www.example.com/org_social.png")
      end

      it "updates organization social image" do
        described_class.call(organization)
        expect(organization.reload.social_image).to eq("https://www.example.com/org_social.png")
      end
    end
  end
end
