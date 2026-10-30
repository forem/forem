require "rails_helper"

RSpec.describe Images::ProfileImageGenerator, type: :service do
  describe ".call" do
    it "returns a valid 400x400 PNG image File" do
      file = described_class.call

      expect(file).to be_a(File)
      expect(File.exist?(file.path)).to be(true)

      image = MiniMagick::Image.open(file.path)
      expect(image.type).to eq("PNG")
      expect(image.dimensions).to eq([400, 400])
    ensure
      file&.close
    end

    it "generates deterministic output for a given seed and distinct output for different seeds" do
      first = described_class.call(seed: 12_345)
      second = described_class.call(seed: 12_345)
      different = described_class.call(seed: 98_765)

      expect(first.read).to eq(second.read)
      first.rewind
      expect(first.read).not_to eq(different.read)
    ensure
      first&.close
      second&.close
      different&.close
    end

    it "falls back to a static asset image if MiniMagick raises an error" do
      allow(MiniMagick::Tool::Convert).to receive(:new).and_raise(MiniMagick::Error, "convert failed")
      allow(Rails.logger).to receive(:warn)

      file = described_class.call

      expect(file).to be_a(File)
      expect(file.path).to include("app/assets/images/")
      expect(Rails.logger).to have_received(:warn).with(/ProfileImageGenerator fallback triggered/)
    ensure
      file&.close
    end
  end

  describe ".backfill_missing!" do
    it "generates and saves profile images for users missing a profile_image" do
      missing_user = create(:user)
      missing_user.update_column(:profile_image, nil)
      existing_user = create(:user)
      original_image = existing_user.attributes["profile_image"]

      count = described_class.backfill_missing!

      expect(count).to eq(1)
      expect(missing_user.reload.attributes["profile_image"]).to be_present
      expect(existing_user.reload.attributes["profile_image"]).to eq(original_image)
    end
  end
end
