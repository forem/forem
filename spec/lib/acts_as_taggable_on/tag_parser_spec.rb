require "rails_helper"

RSpec.describe ActsAsTaggableOn::TagParser do
  let(:tag0) { create(:tag, name: "things") }
  let(:tag1) { create(:tag, name: "peter") }

  let(:tag2) { create(:tag, name: "stuff", alias_for: tag0.name) }

  let(:tag3) { create(:tag, name: "mac", alias_for: tag1.name) }

  def create_tag_parser(tag_arr)
    described_class.new(tag_arr).parse
  end
  describe "#parse" do
    it "removes spaces" do
      tags = ["w o r d", "a pp le"]
      expect(create_tag_parser(tags)).to eq(["word", "apple"])
    end

    it "does not allow dashes" do
      tags = ["w-o-r-d", "a-pp-le"]
      expect(create_tag_parser(tags)).to eq(["word", "apple"])
    end
    it "allows only alphanumeric characters" do
      tags = ["w0rd", "app|3", "&!tes4@#$%^&*"]
      expect(create_tag_parser(tags)).to eq(["w0rd", "app3", "tes4"])
    end
    it "returns nothing if nothing is recieved" do
      expect(create_tag_parser([])).to eq([])
    end
    it "uses tag alias if one exists" do
      tags = [tag2.name, tag3.name]
      expect(create_tag_parser(tags)).to eq [tag2.alias_for, tag3.alias_for]
    end
  end
end
