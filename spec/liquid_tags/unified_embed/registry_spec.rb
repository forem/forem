require "rails_helper"

RSpec.describe UnifiedEmbed::Registry do
  subject(:unified_embed) { described_class }

  let(:article) { create(:article) }

  describe ".find_liquid_tag_for" do
    valid_blogcast_url_formats = [
      "https://blogcast.host/embed/4942",
      "https://app.blogcast.host/embed/4942",
    ]

    valid_codesandbox_url_formats = [
      "https://codesandbox.io/embed/exciting-knuth-hywlv",
      "https://app.codesandbox.io/embed/exciting-knuth-hywlv",
      "https://app.codesandbox.io/embed/exciting-knuth-hywlv?file=/index.html&runonclick=0&view=editor",
    ]

    valid_instagram_url_formats = [
      "https://www.instagram.com/p/CXgzXWXroHK/",
      "https://instagram.com/p/CXgzXWXroHK/",
      "http://www.instagram.com/p/CXgzXWXroHK/",
      "www.instagram.com/p/CXgzXWXroHK/",
      "instagram.com/p/CXgzXWXroHK/",
    ]

    valid_replit_url_formats = [
      "https://replit.com/@msarit/Shell-Challenge#index.html",
      "https://replit.com/@msarit/Shell-Challenge",
    ]

    valid_spotify_url_formats = [
      "https://open.spotify.com/track/64csu9GsP563GpjaSvU17w?si=eaac508fe9394a93",
      "https://open.spotify.com/track/64csu9GsP563GpjaSvU17w",
      "https://open.spotify.com/artist/2Cnw56yEiRmpVI79f9z6oO?si=AJguBjS5QeeFkvSQq6-o7Q",
      "https://open.spotify.com/playlist/37i9dQZF1E39MihYlvYa83?si=4ca24a67215f4eab",
      "https://open.spotify.com/album/3YA5DdB3wSz4pdfEXoMyRd?si=LQ6ft_T9QfiNA_KHbn6CkA",
      "https://open.spotify.com/episode/3fLyjTYjIdHxC0kdKMpbGj?si=5f45e5032cd5450a",
      "https://open.spotify.com/show/3sRrtlRiByFrOC49vPwP8L?si=c3c6c1180afe4094",
    ]

    valid_twitch_url_formats = [
      "https://clips.twitch.tv/embed?clip=SpeedyVivaciousDolphinKappaRoss-IQl5YslMAGKbMOGM&parent=www.example.com",
      "https://player.twitch.tv/?video=1222841752&parent=www.example.com",
      "https://player.twitch.tv/?video=1222841752",
      "https://www.twitch.tv/videos/1250164963",
      "https://www.twitch.tv/monchi_tv/clip/CrepuscularSparklingGalagoBudBlast-ij3jvc4r437D4L4L",
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

    it "returns BlogcastTag for a valid blogcast url" do
      valid_blogcast_url_formats.each do |url|
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(BlogcastTag)
      end
    end

    it "returns CodesandboxTag for a valid codesandbox url" do
      valid_codesandbox_url_formats.each do |url|
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(CodesandboxTag)
      end
    end

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

    it "returns InstagramTag for a valid instagram url" do
      valid_instagram_url_formats.each do |url|
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

    it "returns ReplitTag for a valid replit url" do
      valid_replit_url_formats.each do |url|
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(ReplitTag)
      end
    end

    it "returns SoundcloudTag for a soundcloud url" do
      expect(described_class.find_liquid_tag_for(link: "https://soundcloud.com/before-30-tv/stranger-moni-lati-lo-1"))
        .to eq(SoundcloudTag)
    end

    it "returns SpotifyTag for a valid spotify url" do
      valid_spotify_url_formats.each do |url|
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(SpotifyTag)
      end
    end

    it "returns TwitchTag for a valid twitch url" do
      valid_twitch_url_formats.each do |url|
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(TwitchTag)
      end
    end

    it "returns TwitterTimelineTag for a twitter timeline url" do
      expect(described_class.find_liquid_tag_for(link: "https://twitter.com/FreyaHolmer/timelines/1215413954505297922"))
        .to eq(TwitterTimelineTag)
    end

    it "returns WikipediaTag for a twitter timeline url" do
      expect(described_class.find_liquid_tag_for(link: "https://en.wikipedia.org/wiki/Steve_Jobs"))
        .to eq(WikipediaTag)
    end

    it "returns VimeoTag for a valid vimeo url" do
      valid_vimeo_url_formats.each do |url|
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(VimeoTag)
      end
    end

    it "returns YoutubeTag for a valid youtube url" do
      valid_youtube_url_formats.each do |url|
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(YoutubeTag)
      end
    end
  end
end
