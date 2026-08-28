require "rails_helper"

RSpec.describe Mlh::ProfileMapper, type: :service do
  # Mirrors a /v4/users/me response
  let(:payload) do
    {
      "address" => {
        "line1" => "1 Example Street", "city" => "Brooklyn", "state" => "NY",
        "postal_code" => "11201", "country" => "United States of America", "country_code" => "US"
      },
      "education" => [
        { "current" => true, "school_name" => "Acadia University", "major" => "Computer Science" },
      ],
      "professional_experience" => [
        { "current" => true, "title" => "Software Engineer", "type" => "Full-Time" },
      ],
      "profile" => { "pronouns" => "she/her" }
    }
  end

  # ProfileMapper resolves fields by label, so those fields must exist
  before do
    group = create(:profile_field_group, name: "Basic")
    { "Work" => "work", "Education" => "education", "Pronouns" => "pronouns" }.each do |label, attribute_name|
      create(:profile_field, label: label, profile_field_group: group).update!(attribute_name: attribute_name)
    end
    Profile.refresh_attributes!
  end

  after { Profile.refresh_attributes! }

  describe ".call" do
    it "maps location and the configured fields by attribute_name" do
      expect(described_class.call(payload)).to eq(
        "location" => "Brooklyn, NY, US",
        "work" => "Software Engineer",
        "education" => "Acadia University, Computer Science",
        "pronouns" => "she/her",
      )
    end

    it "omits fields this Forem has not configured" do
      ProfileField.where(label: %w[Work Pronouns]).find_each(&:destroy)

      expect(described_class.call(payload).keys).to contain_exactly("location", "education")
    end

    it "leaves the street address out of location" do
      expect(described_class.call(payload)["location"]).not_to include("1 Example Street")
    end

    it "prefers current records over past ones" do
      payload["education"] = [
        { "current" => false, "school_name" => "Past University", "major" => "History" },
        { "current" => true, "school_name" => "Acadia University", "major" => "Computer Science" },
      ]

      expect(described_class.call(payload)["education"]).to eq("Acadia University, Computer Science")
    end

    it "falls back to the first record when none is current" do
      payload["education"] = [{ "current" => false, "school_name" => "Past University" }]

      expect(described_class.call(payload)["education"]).to eq("Past University")
    end

    it "drops blank values" do
      payload["profile"] = { "pronouns" => "" }
      payload["professional_experience"] = []

      expect(described_class.call(payload).keys).to contain_exactly("location", "education")
    end

    it "returns an empty hash for an empty payload" do
      expect(described_class.call({})).to eq({})
    end

    it "builds location from whichever address parts are present" do
      payload["address"] = { "city" => "Brooklyn", "state" => nil, "country_code" => "US" }

      expect(described_class.call(payload)["location"]).to eq("Brooklyn, US")
    end

    it "keeps location within the length Forem validates" do
      payload["address"] = { "city" => "a" * 200, "country_code" => "US" }

      expect(described_class.call(payload)["location"].length).to be <= described_class::LOCATION_MAX_LENGTH
    end
  end
end
