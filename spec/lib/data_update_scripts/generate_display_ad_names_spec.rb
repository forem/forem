require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220830153942_generate_display_ad_names.rb",
)

describe DataUpdateScripts::GenerateDisplayAdNames do
  context "when there is no name for a billboard" do
    it "generates a name for an existing Billboard" do
      billboard = create(:billboard, name: nil)

      described_class.new.run
      expect(billboard.reload.name).to eq("Billboard #{billboard.id}")
    end
  end

  context "when there is a name for the Billboard" do
    it "does not change the name" do
      billboard = create(:billboard, name: "Test")

      expect do
        described_class.new.run
      end.not_to change { billboard.reload.name }
    end
  end
end
