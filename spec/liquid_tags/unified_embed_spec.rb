require "rails_helper"

RSpec.describe UnifiedEmbed do
  subject(:unified_embed) { described_class }

  describe ".find_liquid_tag_for" do
    it "returns GistTag for a gist url" do
      expect(described_class.find_liquid_tag_for(link: "https://gist.github.com/jeremyf/662585f5c4d22184a6ae133a71bf891a"))
        .to eq(GistTag)
    end

    it "returns AsciinemaTag for an asciinema url" do
      expect(described_class.find_liquid_tag_for(link: "https://asciinema.org/a/330532"))
        .to eq(AsciinemaTag)
    end

    it "returns CodepenTag for a codepen url" do
      expect(described_class.find_liquid_tag_for(link: "https://codepen.io/elisavetTriant/pen/KKvRRyE"))
        .to eq(CodepenTag)
    end

    it "returns JsFiddle for a jsfiddle url" do
      expect(described_class.find_liquid_tag_for(link: "http://jsfiddle.net/link2twenty/v2kx9jcd"))
        .to eq(JsFiddleTag)
    end

    it "returns NextTechTag for a nexttech url" do
      expect(described_class.find_liquid_tag_for(link: "https://nt.dev/s/6ba1fffbd09e"))
        .to eq(NextTechTag)
    end

    it "returns RedditTag for a reddit url" do
      expect(described_class.find_liquid_tag_for(link: "https://www.reddit.com/r/Cricket/comments/qrkwol/match_thread_2nd_semifinal_australia_vs_pakistan/"))
        .to eq(RedditTag)
    end

    it "returns SoundcloudTag for a soundcloud url" do
      expect(described_class.find_liquid_tag_for(link: "https://soundcloud.com/before-30-tv/stranger-moni-lati-lo-1"))
        .to eq(SoundcloudTag)
    end

    it "returns TwitterTimelineTag for a twitter timeline url" do
      expect(described_class.find_liquid_tag_for(link: "https://twitter.com/FreyaHolmer/timelines/1215413954505297922"))
        .to eq(TwitterTimelineTag)
    end

    it "returns WikipediaTag for a twitter timeline url" do
      expect(described_class.find_liquid_tag_for(link: "https://en.wikipedia.org/wiki/Steve_Jobs"))
        .to eq(WikipediaTag)
    end

    it "returns YoutubeTag for a youtube url" do
      expect(described_class.find_liquid_tag_for(link: "https://www.youtube.com/embed/dQw4w9WgXcQ"))
        .to eq(YoutubeTag)
    end
  end
end
