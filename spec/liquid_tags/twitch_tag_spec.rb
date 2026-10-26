require "rails_helper"
require "nokogiri"

RSpec.describe TwitchTag, type: :liquid_tag do
  let(:clip_slug) { "CuteSpicyNostrilDoritosChip" }
  let(:video_id) { "1196406756" }

  def assert_parses_clip(slug, token)
    liquid = Liquid::Template.parse("{% twitch #{token} %}").render
    expect(liquid).to include "https://clips.twitch.tv/embed?clip=#{slug}&amp;parent=forem.test&amp;autoplay=false"
  end

  def assert_parses_video(id, token)
    liquid = Liquid::Template.parse("{% twitch #{token} %}").render
    expect(liquid).to include "https://player.twitch.tv/?video=#{id}&amp;parent=forem.test&amp;autoplay=false"
  end

  context "when twitch clip slug passed in" do
    it "accepts slug" do
      assert_parses_clip clip_slug, clip_slug
    end

    it "accepts slug with wonky whitespace" do
      assert_parses_clip clip_slug, " #{clip_slug}  \t"
    end
  end

  context "when twitch video id passed in" do
    it "accepts id" do
      assert_parses_video video_id, video_id
    end

    it "accepts id with wonky whitespace" do
      assert_parses_video video_id, " #{video_id}  \t"
    end
  end

  it "prevents param injection" do
    assert_parses_clip clip_slug, "#{clip_slug}&autoplay=true"
    assert_parses_video video_id, "#{video_id}&muted=true"
  end

  context "when Twitch player URL has reordered query params" do
    it "accepts player url with parent param before video param" do
      url = "https://player.twitch.tv/?parent=localhost&video=#{video_id}&autoplay=false"
      assert_parses_video video_id, url
    end

    it "accepts player url with multiple params before video param" do
      url = "https://player.twitch.tv/?autoplay=false&parent=localhost&video=#{video_id}"
      assert_parses_video video_id, url
    end

    it "rejects non-Twitch URLs containing player.twitch.tv in the path" do
      url = "https://example.com/player.twitch.tv/?video=#{video_id}"
      expect do
        Liquid::Template.parse("{% twitch #{url} %}").render
      end.to raise_error(StandardError, I18n.t("liquid_tags.twitch_tag.invalid_twitch_id"))
    end
  end
end
