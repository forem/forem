require "rails_helper"
require "nokogiri"

RSpec.describe TwitchTag, type: :liquid_tag do
  let(:clip_slug) { "CuteSpicyNostrilDoritosChip" }
  let(:video_id) { "1196406756" }

  def assert_parses_clip(slug, token)
    liquid = Liquid::Template.parse("{% twitch #{token} %}").render
    expect(liquid).to include "https://clips.twitch.tv/embed?clip=#{slug}&amp;parent=localhost&amp;autoplay=false"
  end

  def assert_parses_video(id, token)
    liquid = Liquid::Template.parse("{% twitch #{token} %}").render
    expect(liquid).to include "https://player.twitch.tv/?video=#{id}&amp;parent=localhost&amp;autoplay=false"
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
end
