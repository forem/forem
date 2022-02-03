require "rails_helper"

RSpec.describe UnifiedEmbed::Registry do
  subject(:unified_embed) { described_class }

  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let(:comment) do
    create(:comment, commentable: article, user: user, body_markdown: "TheComment")
  end
  let(:organization) { create(:organization) }

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

    valid_glitch_url_formats = [
      "https://zircon-quixotic-attraction.glitch.me",
      "https://glitch.com/edit/#!/zircon-quixotic-attraction",
      "https://glitch.com/edit/#!/zircon-quixotic-attraction?path=script.js:1:0",
    ]

    valid_medium_url_formats = [
      "https://medium.com/@edisonywh/my-ruby-journey-hooking-things-up-91d757e1c59c",
      "https://themobilist.medium.com/is-universal-basic-mobility-the-route-to-a-sustainable-c-b18e1e2d014c",
    ]

    valid_instagram_url_formats = [
      "https://www.instagram.com/p/CXgzXWXroHK/",
      "https://instagram.com/p/CXgzXWXroHK/",
      "http://www.instagram.com/p/CXgzXWXroHK/",
      "www.instagram.com/p/CXgzXWXroHK/",
      "instagram.com/p/CXgzXWXroHK/",
    ]

    valid_kotlin_url_formats = [
      "https://pl.kotl.in/mCMciWl85",
      "https://pl.kotl.in/owreUFFUG?theme=darcula",
      "https://pl.kotl.in/Wplen1rPa?theme=darcula&readOnly=true&from=6&to=7",
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

    valid_stackblitz_url_formats = [
      "https://stackblitz.com/edit/web-platform-3tqbd4",
      "https://stackblitz.com/edit/web-platform-3tqbd4?embed=1&file=index.html&hideExplorer=1&hideNavigation=1&theme=dark",
      "https://stackblitz.com/edit/web-platform-3tqbd4?embed=1&file=index.html&theme=light",
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

    it "returns BlogcastTag for a valid blogcast url", :aggregate_failures do
      valid_blogcast_url_formats.each do |url|
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(BlogcastTag)
      end
    end

    it "returns CodesandboxTag for a valid codesandbox url", :aggregate_failures do
      valid_codesandbox_url_formats.each do |url|
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(CodesandboxTag)
      end
    end

    it "returns CommentTag for a Forem comment url" do
      expect(described_class.find_liquid_tag_for(link: "#{URL.url}/#{user.username}/comment/#{comment.id_code}"))
        .to eq(CommentTag)
    end

    it "returns GistTag for a gist url" do
      expect(described_class.find_liquid_tag_for(link: "https://gist.github.com/jeremyf/662585f5c4d22184a6ae133a71bf891a"))
        .to eq(GistTag)
    end

    it "returns GlitchTag for a valid glitch url", :aggregate_failures do
      valid_glitch_url_formats.each do |url|
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(GlitchTag)
      end
    end

    it "returns AsciinemaTag for an asciinema url" do
      expect(described_class.find_liquid_tag_for(link: "https://asciinema.org/a/330532"))
        .to eq(AsciinemaTag)
    end

    it "returns CodepenTag for a codepen url" do
      expect(described_class.find_liquid_tag_for(link: "https://codepen.io/elisavetTriant/pen/KKvRRyE"))
        .to eq(CodepenTag)
    end

    it "returns DotnetFiddleTag for a dotnetfiddle url" do
      expect(described_class.find_liquid_tag_for(link: "https://dotnetfiddle.net/PmoDip"))
        .to eq(DotnetFiddleTag)
    end

    it "returns InstagramTag for a valid instagram url", :aggregate_failures do
      valid_instagram_url_formats.each do |url|
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(InstagramTag)
      end
    end

    it "returns JsFiddle for a jsfiddle url" do
      expect(described_class.find_liquid_tag_for(link: "http://jsfiddle.net/link2twenty/v2kx9jcd"))
        .to eq(JsFiddleTag)
    end

    it "returns KotlinTag for a valid kotlin url", :aggregate_failures do
      valid_kotlin_url_formats.each do |url|
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(KotlinTag)
      end
    end

    it "returns JsitorTag for a jsitor url" do
      expect(described_class.find_liquid_tag_for(link: "https://jsitor.com/embed/B7FQ5tHbY"))
        .to eq(JsitorTag)
    end

    it "returns Forem Link for a forem url" do
      expect(described_class.find_liquid_tag_for(link: URL.url + article.path))
        .to eq(LinkTag)
    end

    it "returns MediumTag for a valid medium url", :aggregate_failures do
      valid_medium_url_formats.each do |url|
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(MediumTag)
      end
    end

    it "returns NextTechTag for a nexttech url" do
      expect(described_class.find_liquid_tag_for(link: "https://nt.dev/s/6ba1fffbd09e"))
        .to eq(NextTechTag)
    end

    it "returns OrganizationTag for a Forem organization url" do
      expect(described_class.find_liquid_tag_for(link: "#{URL.url}/#{organization.slug}"))
        .to eq(OrganizationTag)
    end

    it "returns RedditTag for a reddit url" do
      expect(described_class.find_liquid_tag_for(link: "https://www.reddit.com/r/Cricket/comments/qrkwol/match_thread_2nd_semifinal_australia_vs_pakistan/"))
        .to eq(RedditTag)
    end

    it "returns ReplitTag for a valid replit url", :aggregate_failures do
      valid_replit_url_formats.each do |url|
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(ReplitTag)
      end
    end

    it "returns SlideshareTag for a slideshare url" do
      expect(described_class.find_liquid_tag_for(link: "https://www.slideshare.net/slideshow/embed_code/key/d5rGkEgXFDRN17"))
        .to eq(SlideshareTag)
    end

    it "returns SoundcloudTag for a soundcloud url" do
      expect(described_class.find_liquid_tag_for(link: "https://soundcloud.com/before-30-tv/stranger-moni-lati-lo-1"))
        .to eq(SoundcloudTag)
    end

    it "returns SpeakerdeckTag for a speakerdeck url" do
      expect(described_class.find_liquid_tag_for(link: "https://speakerdeck.com/player/87fa761026bf013092b722000a1d8877"))
        .to eq(SpeakerdeckTag)
    end

    it "returns SpotifyTag for a valid spotify url", :aggregate_failures do
      valid_spotify_url_formats.each do |url|
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(SpotifyTag)
      end
    end

    it "returns StackblitzTag for a valid stackblitz url", :aggregate_failures do
      valid_stackblitz_url_formats.each do |url|
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(StackblitzTag)
      end
    end

    it "returns StackeryTag for a stackery url" do
      expect(described_class.find_liquid_tag_for(link: "https://app.stackery.io/editor/design?owner=stackery&repo=quickstart-ruby&file=template.yaml"))
        .to eq(StackeryTag)
    end

    it "returns TweetTag for a tweet url" do
      expect(described_class.find_liquid_tag_for(link: "https://twitter.com/aritdeveloper/status/1483614684884484099"))
        .to eq(TweetTag)
    end

    it "returns TwitchTag for a valid twitch url", :aggregate_failures do
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

    it "returns VimeoTag for a valid vimeo url", :aggregate_failures do
      valid_vimeo_url_formats.each do |url|
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(VimeoTag)
      end
    end

    it "returns YoutubeTag for a valid youtube url", :aggregate_failures do
      valid_youtube_url_formats.each do |url|
        expect(described_class.find_liquid_tag_for(link: url))
          .to eq(YoutubeTag)
      end
    end
  end
end
