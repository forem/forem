require "rails_helper"
require "rss"

RSpec.describe Podcasts::EpisodeRssItem, type: :service do
  let(:enclosure) do
    instance_double(RSS::Rss::Channel::Item::Enclosure, url: "https://audio.simplecast.com/2330f132.mp3")
  end
  let(:guid) { "<guid isPermaLink=\"false\">http://podcast.example/file.mp3</guid>" }
  let(:item) do
    instance_double(RSS::Rss::Channel::Item, pubDate: "2019-06-19",
                                             enclosure: enclosure,
                                             description: "yet another podcast",
                                             title: "lightalloy's podcast",
                                             guid: guid,
                                             itunes_subtitle: "hello",
                                             content_encoded: nil,
                                             itunes_summary: "world",
                                             link: "https://litealloy.ru")
  end

  describe "#new" do
    it "create a nice object" do
      data = described_class.new(title: "a", itunes_subtitle: "b", itunes_summary: "c",
                                 link: "https://example.com", guid: "guid", pubDate: "2019-01-01",
                                 body: "100", enclosure_url: "example.example")
      expect(data.title).to eq("a")
    end
  end

  describe "#from_item" do
    it "returns a hash" do
      attributes = described_class.from_item(item).to_h
      expect(attributes).to be_kind_of(Hash)
      expect(attributes[:title]).to eq("lightalloy's podcast")
      expect(attributes[:enclosure_url]).to eq("https://audio.simplecast.com/2330f132.mp3")
      expect(attributes[:body]).to eq("world")
    end

    it "has attr readers" do
      data = described_class.from_item(item)
      expect(data.guid).to eq(guid)
      expect(data.enclosure_url).to eq("https://audio.simplecast.com/2330f132.mp3")
      expect(data.link).to eq(item.link)
    end

    it "sets url to nil when no enclosure" do
      item = RSS::Parser.parse("spec/support/fixtures/podcasts/arresteddevops.xml", false).items.first
      data = described_class.from_item(item)
      expect(data.enclosure_url).to be_nil
    end
  end
end
