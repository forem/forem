require "rails_helper"

RSpec.describe Ai::TypeSafe::Questions do
  describe ".noul" do
    it "omits criteria when none are given" do
      expect(described_class.noul("Is it urgent?")).to eq(type: "noul", instructions: "Is it urgent?")
    end

    it "sends yes/no descriptions as the API's true/false criteria" do
      question = described_class.noul("Is it urgent?", yes: "Time-sensitive", no: { includes: "Routine questions" })

      expect(question[:criteria]).to eq("true" => "Time-sensitive", "false" => { includes: "Routine questions" })
    end
  end

  describe ".choice" do
    it "stringifies option keys" do
      expect(described_class.choice("Which?", { a: "A", b: nil })[:criteria]).to eq("a" => "A", "b" => nil)
    end

    it "enforces the API's option limits" do
      expect { described_class.choice("Which?", { a: nil }) }.to raise_error(ArgumentError)
      too_many = (0..described_class::MAX_CHOICE_OPTIONS).to_h { |index| ["option_#{index}", nil] }
      expect { described_class.choice("Which?", too_many) }.to raise_error(ArgumentError)
    end
  end

  describe ".score" do
    it "enforces the API's level limits" do
      expect { described_class.score("How?", ["Only one"]) }.to raise_error(ArgumentError)
      expect { described_class.score("How?", Array.new(11) { |index| "Level #{index}" }) }.to raise_error(ArgumentError)
    end
  end
end
