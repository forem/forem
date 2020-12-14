require "rails_helper"
require "nokogiri"

RSpec.describe TwitchTag, type: :liquid_tag do
  let(:slug) { "CuteSpicyNostrilDoritosChip" }

  def assert_parses(slug, token)
    liquid = Liquid::Template.parse("{% twitch #{token} %}").render
    expect(liquid).to include "https://clips.twitch.tv/embed?autoplay=false&clip=#{slug}&parent=localhost"
  end

  it "accepts twitch clip slug" do
    assert_parses slug, slug
  end

  it "accepts twitch clip slug with wonky whitespace" do
    assert_parses slug, " #{slug}  \t"
  end

  it "forbids inserting autoplay option" do
    assert_parses slug, "#{slug}&autoplay=true"
  end

  it "forbids inserting mute option" do
    assert_parses slug, "#{slug}&muted=true"
  end
end
