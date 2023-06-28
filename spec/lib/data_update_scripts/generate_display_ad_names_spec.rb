require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220830153942_generate_display_ad_names.rb",
)

describe DataUpdateScripts::GenerateDisplayAdNames do
  context "when there is no name for a Display Ad" do
    it "generates a name for an existing Display Ad" do
      display_ad = create(:display_ad, name: nil)

      described_class.new.run
      expect(display_ad.reload.name).to eq("Display Ad #{display_ad.id}")
    end
  end

  context "when there is a name for the Display Ad" do
    it "does not change the name" do
      display_ad = create(:display_ad, name: "Test")

      expect do
        described_class.new.run
      end.not_to change { display_ad.reload.name }
    end
  end
end
