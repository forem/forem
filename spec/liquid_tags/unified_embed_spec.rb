require "rails_helper"

RSpec.describe UnifiedEmbed do
  subject(:unified_embed) { described_class }

  describe ".find_liquid_tag_for" do
    it "returns GistTag for a gist url" do
      expect(described_class.find_liquid_tag_for(link: "https://gist.github.com/jeremyf/662585f5c4d22184a6ae133a71bf891a"))
        .to eq(GistTag)
    end
  end
end
