require "rails_helper"

RSpec.describe ActsAsTaggableOn::TagParser, type: :lib do
  let(:tag0) { create(:tag, name: "things") }
  let(:tag1) { create(:tag, name: "peter") }

  let(:tag2) { create(:tag, name: "stuff", alias_for: tag0.name) }

  let(:tag3) { create(:tag, name: "mac", alias_for: tag1.name) }

  def create_tag_parser(tag_arr)
    described_class.new(tag_arr).parse
  end
  describe "#parse" do
    xit "removes spaces" do
      tags = ["w o r d", "a pp le"]
      expect(create_tag_parser(tags)).to eq(%w[word apple])
    end

    xit "does not allow dashes" do
      tags = ["w-o-r-d", "a-pp-le"]
      expect(create_tag_parser(tags)).to eq(%w[word apple])
    end

    xit "allows only alphanumeric characters" do
      tags = ["w0rd", "app|3", "&!tes4@#$%^&*"]
      expect(create_tag_parser(tags)).to eq(%w[w0rd app3 tes4])
    end

    xit "allows non-english characters" do
      tags = %w[Optimización Καλημέρα Français]
      expect(create_tag_parser(tags)).to eq(%w[optimización καλημέρα français])
    end

    xit "returns nothing if nothing is received" do
      expect(create_tag_parser([])).to eq([])
    end

    xit "uses tag alias if one exists" do
      tags = [tag2.name, tag3.name]
      expect(create_tag_parser(tags)).to eq [tag2.alias_for, tag3.alias_for]
    end
  end
end
