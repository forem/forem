require "rails_helper"

RSpec.describe UnifiedEmbed do
  subject(:unified_embed) { described_class }

  describe ".find_liquid_tag_for" do
    it "returns GistTag for a gist url" do
      expect(described_class.find_liquid_tag_for(link: "https://gist.github.com/jeremyf/662585f5c4d22184a6ae133a71bf891a"))
        .to eq(GistTag)
    end

    it "returns AsciinemaTag for a gist url" do
      expect(described_class.find_liquid_tag_for(link: "https://asciinema.org/a/330532"))
        .to eq(AsciinemaTag)
    end

    it "returns CodepenTag for a gist url" do
      expect(described_class.find_liquid_tag_for(link: "https://codepen.io/elisavetTriant/pen/KKvRRyE"))
        .to eq(CodepenTag)
    end
  end
end
