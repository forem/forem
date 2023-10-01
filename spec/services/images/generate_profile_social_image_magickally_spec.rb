require "rails_helper"

RSpec.describe Images::GenerateProfileSocialImageMagickally, type: :model do
  let(:user) { create(:user) }
  let(:generator) { described_class.new(user) }

  before do
    allow(Images::GenerateSocialImageMagickally).to receive(:new).and_return(generator)
    allow(generator).to receive(:read_files)
    allow(generator).to receive(:generate_magickally)
    allow(user).to receive(:profile).and_return(instance_double(Profile))
    allow(user.profile).to receive(:update_column)
    allow(Rails.logger).to receive(:error)
    allow(Honeybadger).to receive(:notify)
  end

  describe ".call" do
    it "reads necessary files" do
      described_class.call(user)
      expect(generator).to have_received(:read_files)
    end

    it "generates the image magickally" do
      described_class.call(user)
      expect(generator).to have_received(:generate_magickally).with(
        author_name: user.name,
        color: user.setting.brand_color1,
      )
    end

    it "updates user profile to have social image" do
      allow(generator).to receive(:generate_magickally).and_return("https://www.example.com")
      described_class.call(user)
      expect(user.profile).to have_received(:update_column).with(:social_image, "https://www.example.com")
    end

    context "when an exception is raised" do
      it "logs and notifies the error" do
        allow(generator).to receive(:read_files).and_raise(StandardError.new("some error"))
        described_class.call(user)
        expect(Rails.logger).to have_received(:error).with(instance_of(StandardError))
        expect(Honeybadger).to have_received(:notify).with(instance_of(StandardError))
      end
    end
  end
end
