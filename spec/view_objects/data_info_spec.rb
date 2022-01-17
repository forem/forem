require "rails_helper"

RSpec.describe DataInfo, type: :view_object do
  describe "#to_json" do
    subject(:results) { described_class.to_json(**parameters) }

    # Including two characters of special purpose, the double hack
    # (e.g. '"') and the backslash (e.g. '\').  These were causing
    # upstream problems.
    let(:user) { build(:user, id: 123, name: "Duane \"The Rock\" Johnson \\\\.//") }

    context "when given a User" do
      let(:parameters) { { object: user } }

      it "parses to valid JSON" do
        expect(JSON.parse(results))
          .to eq({ "className" => "User", "id" => 123, "name" => "Duane \"The Rock\" Johnson \\\\.//" })
      end
    end

    context "when given a User with additional attributes" do
      let(:parameters) { { object: user, id: 8_675_309, style: "full" } }

      it "parses to valid JSON" do
        expect(JSON.parse(results))
          .to eq({ "className" => "User", "id" => 8_675_309, "name" => "Duane \"The Rock\" Johnson \\\\.//",
                   "style" => "full" })
      end
    end

    context "when given a Tag" do
      let(:tag) { build(:tag, id: 1234) }
      let(:parameters) { { object: tag } }

      it "parses to valid JSON" do
        expect(JSON.parse(results))
          .to eq({ "className" => "Tag", "id" => tag.id, "name" => tag.name })
      end
    end
  end
end
