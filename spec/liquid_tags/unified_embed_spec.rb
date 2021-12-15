require "rails_helper"

RSpec.describe UnifiedEmbed do
  subject(:unified_embed) { described_class }

  let(:article) { create(:article) }

  describe ".find_liquid_tag_for" do
    valid_instagram_url_formats = [
      "https://www.instagram.com/p/CXgzXWXroHK/",
      "https://instagram.com/p/CXgzXWXroHK/",
      "http://www.instagram.com/p/CXgzXWXroHK/",
      "www.instagram.com/p/CXgzXWXroHK/",
      "instagram.com/p/CXgzXWXroHK/",
    ]

    valid_vimeo_url_formats = [
      "https://player.vimeo.com/video/652446985?h=a68f6ed1f5",
      "https://vimeo.com/ondemand/withchude/647355334",
      "https://vimeo.com/636725488",
    ]

    valid_youtube_url_formats = [
      "https://www.youtube.com/embed/dQw4w9WgXcQ",
      "https://www.youtube.com/watch?v=rc5AyncB_Xw&t=18s",
      "https://youtu.be/rc5AyncB_Xw",
    ]

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

    valid_instagram_url_formats.each do |url|
      it "returns InstagramTag for a valid instagram url format" do
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(InstagramTag)
      end
    end

    it "returns JsFiddle for a jsfiddle url" do
      expect(described_class.find_liquid_tag_for(link: "http://jsfiddle.net/link2twenty/v2kx9jcd"))
        .to eq(JsFiddleTag)
    end

    it "returns Forem Link for a forem url" do
      expect(described_class.find_liquid_tag_for(link: URL.url + article.path))
        .to eq(LinkTag)
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

    valid_vimeo_url_formats.each do |url|
      it "returns VimeoTag for a valid vimeo url format" do
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(VimeoTag)
      end
    end

    valid_youtube_url_formats.each do |url|
      it "returns YoutubeTag for a valid youtube url format" do
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(YoutubeTag)
      end
    end
  end
end
