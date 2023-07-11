require "rails_helper"

RSpec.describe Location do
  describe "validations" do
    describe "country validation" do
      it "allows only ISO-3166 countries" do
        united_states = described_class.new("US")
        netherlands = described_class.new("NL")
        india = described_class.new("IN")
        south_africa = described_class.new("ZA")
        unassigned_country = described_class.new("ZZ")
        invalid_code_country = described_class.new("not iso3166")

        expect(united_states).to be_valid
        expect(netherlands).to be_valid
        expect(india).to be_valid
        expect(south_africa).to be_valid
        expect(unassigned_country).not_to be_valid
        expect(invalid_code_country).not_to be_valid
      end
    end

    describe "subdivision validation" do
      it "allows an empty subdivision" do
        without_subdivision = described_class.new("US")
        expect(without_subdivision).to be_valid
      end

      it "allows only subdivisions that are a part of the country" do
        # CA: State of California (within the US)
        # BRE: Metropolitan region of Bretagne (within France)
        us_with_us_sub = described_class.new("US", "CA")
        us_with_france_sub = described_class.new("US", "BRE")
        france_with_us_sub = described_class.new("FR", "CA")
        france_with_france_sub = described_class.new("FR", "BRE")

        expect(us_with_us_sub).to be_valid
        expect(us_with_france_sub).not_to be_valid
        expect(france_with_us_sub).not_to be_valid
        expect(france_with_france_sub).to be_valid
      end
    end
  end
end
