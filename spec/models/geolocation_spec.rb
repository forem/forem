require "rails_helper"

RSpec.describe Geolocation do
  describe "validations" do
    describe "country validation" do
      let(:united_states) { described_class.new("US") }
      let(:canada) { described_class.new("CA") }
      let(:netherlands) { described_class.new("NL") }
      let(:india) { described_class.new("IN") }
      let(:south_africa) { described_class.new("ZA") }
      let(:unassigned_country) { described_class.new("ZZ") }
      let(:invalid_code_country) { described_class.new("not iso3166") }

      it "allows only the US and Canada by default" do
        expect(united_states).to be_valid
        expect(canada).to be_valid
        expect(netherlands).not_to be_valid
        expect(india).not_to be_valid
        expect(south_africa).not_to be_valid
        expect(unassigned_country).not_to be_valid
        expect(invalid_code_country).not_to be_valid
      end

      it "respects the specified enabled locations in the settings" do
        allow(Settings::General).to receive(:billboard_enabled_countries).and_return(
          "CA" => :without_regions,
          "IN" => :without_regions,
          "ZA" => :without_regions,
        )

        expect(united_states).not_to be_valid
        expect(canada).to be_valid
        expect(netherlands).not_to be_valid
        expect(india).to be_valid
        expect(south_africa).to be_valid
        expect(unassigned_country).not_to be_valid
        expect(invalid_code_country).not_to be_valid
      end
    end

    describe "region validation" do
      # WA: State of Washington (within the US)
      # QC: Province of Québec (within Canada)
      let(:us_with_us_region) { described_class.new("US", "WA") }
      let(:canada_with_canada_region) { described_class.new("CA", "QC") }
      let(:us_with_canada_region) { described_class.new("US", "QC") }
      let(:canada_with_us_region) { described_class.new("CA", "WA") }

      it "allows an empty region" do
        without_region = described_class.new("US")
        expect(without_region).to be_valid
      end

      it "allows only regions that are a part of the country" do
        expect(us_with_us_region).to be_valid
        expect(canada_with_canada_region).to be_valid
        expect(us_with_canada_region).not_to be_valid
        expect(canada_with_us_region).not_to be_valid
      end

      # rubocop:disable RSpec/NestedGroups
      context "when the country does not allow region targeting" do
        before do
          allow(Settings::General).to receive(:billboard_enabled_countries).and_return(
            "US" => :without_regions,
            "CA" => :with_regions,
          )
        end

        it "allows regions for the country by default (for querying)" do
          expect(us_with_us_region).to be_valid
          expect(canada_with_canada_region).to be_valid
          expect(us_with_canada_region).not_to be_valid
          expect(canada_with_us_region).not_to be_valid
        end

        it "does not allow regions for the country in a targeting context" do
          expect(us_with_us_region).not_to be_valid(:targeting)
          expect(canada_with_canada_region).to be_valid(:targeting)
          expect(us_with_canada_region).not_to be_valid(:targeting)
          expect(canada_with_us_region).not_to be_valid(:targeting)
        end
      end
      # rubocop:enable RSpec/NestedGroups
    end
  end

  describe "parsing" do
    shared_examples "handles edge cases" do
      context "when the code to be parsed is nil" do
        let(:code) { nil }

        it { is_expected.to be_nil }
      end

      context "when the code to be parsed is an empty string" do
        let(:code) { "" }

        it { is_expected.to be_nil }
      end

      context "when the code to be parsed is already a geolocation" do
        let(:code) { described_class.new("US") }

        it { is_expected.to eq(code) }
      end
    end

    describe ".from_iso3166" do
      subject(:geo) { described_class.from_iso3166(code) }

      let(:code) { "US-ME" } # Maine, USA

      it "returns the correct geolocation from an ISO 3166-2 format code" do
        expect(geo).to be_valid
        expect(geo.country_code).to eq("US")
        expect(geo.region_code).to eq("ME")
      end

      include_examples "handles edge cases"
    end

    describe ".from_ltree" do
      subject(:geo) { described_class.from_ltree(code) }

      let(:code) { "CA.NL" } # Newfoundland, Canada

      it "returns the correct geolocation from a Postgres ltree format" do
        expect(geo).to be_valid
        expect(geo.country_code).to eq("CA")
        expect(geo.region_code).to eq("NL")
      end

      include_examples "handles edge cases"
    end
  end

  describe "equality" do
    let(:texas) { described_class.new("US", "TX") }
    let(:ontario) { described_class.new("CA", "ON") }

    it "considers two geolocations equal if their country and region codes are equal" do
      expect(texas).to eq(described_class.new("US", "TX"))
      expect(texas).not_to eq(described_class.new("US", "CA"))
      expect(ontario).to eq(described_class.new("CA", "ON"))
      expect(ontario).not_to eq(described_class.new("CA", "QC"))
      expect(texas).not_to eq(ontario)
    end
  end
end
