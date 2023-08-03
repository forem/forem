require "rails_helper"

RSpec.describe Geolocation do
  describe "validations" do
    describe "country validation" do
      it "allows only the US and Canada (for now)" do
        united_states = described_class.new("US")
        canada = described_class.new("CA")
        netherlands = described_class.new("NL")
        india = described_class.new("IN")
        south_africa = described_class.new("ZA")
        unassigned_country = described_class.new("ZZ")
        invalid_code_country = described_class.new("not iso3166")

        expect(united_states).to be_valid
        expect(canada).to be_valid
        expect(netherlands).not_to be_valid
        expect(india).not_to be_valid
        expect(south_africa).not_to be_valid
        expect(unassigned_country).not_to be_valid
        expect(invalid_code_country).not_to be_valid
      end
    end

    describe "region validation" do
      it "allows an empty region" do
        without_region = described_class.new("US")
        expect(without_region).to be_valid
      end

      it "allows only regions that are a part of the country" do
        # WA: State of Washington (within the US)
        # QC: Province of Québec (within Canada)
        us_with_us_region = described_class.new("US", "WA")
        canada_with_canada_region = described_class.new("CA", "QC")
        us_with_canada_region = described_class.new("US", "QC")
        canada_with_us_region = described_class.new("CA", "WA")

        expect(us_with_us_region).to be_valid
        expect(canada_with_canada_region).to be_valid
        expect(us_with_canada_region).not_to be_valid
        expect(canada_with_us_region).not_to be_valid
      end
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
