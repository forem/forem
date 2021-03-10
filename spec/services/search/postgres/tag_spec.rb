require "rails_helper"

RSpec.describe Search::Postgres::Tag, type: :service do
  describe "::search_documents" do
    it "does not find non supported tags" do
      tag = create(:tag, supported: false)

      expect(described_class.search_documents(tag.name)).to be_empty
    end

    it "returns data in the expected format" do
      tag = create(:tag, supported: true)

      result = described_class.search_documents(tag.name)

      expect(result.first.keys).to match_array(
        %w[id name hotness_score rules_html supported short_summary],
      )
    end

    it "finds a tag by its name" do
      tag = create(:tag, supported: true)

      expect(described_class.search_documents(tag.name)).to be_present
    end

    it "finds a tag by a partial name" do
      tag = create(:tag, supported: true)

      expect(described_class.search_documents(tag.name.first(1))).to be_present
    end

    it "finds multiple tags whose names have common parts", :aggregate_failures do
      java = create(:tag, name: "java")
      javascript = create(:tag, name: "javascript")
      ruby = create(:tag, name: "ruby")

      result = described_class.search_documents("jav")
      tags = result.map { |r| r["name"] }

      expect(tags).to include(java.name)
      expect(tags).to include(javascript.name)
      expect(tags).not_to include(ruby.name)
    end

    it "order tags by decreasing hotness score" do
      tag1 = create(:tag, name: "javascript1")
      tag2 = create(:tag, name: "javascript2")

      # see Tag#calculate_hotness_score
      create(:article, score: 50, tags: [], tag_list: tag1.name)
      create(:article, score: 100, tags: [], tag_list: tag2.name)

      # to re-calculate the score
      tag1.save!
      tag2.save!

      result = described_class.search_documents("jav")
      tags = result.map { |r| r["name"] }

      expect(tags).to eq([tag2.name, tag1.name])
    end
  end
end
