require "rails_helper"

RSpec.describe "Search::Multisearch" do
  before do
    create(
      :article,
      body_markdown: "---\ntitle: SearchArticle\n---\n\nWow, search",
    )
    create(:podcast_episode, title: "SearchPodcastEpisode", body: "Wow, more search")
  end

  describe ".call" do
    it "finds articles", :aggregate_failures do
      search_result = Search::Multisearch.call("searcharticle")
      expect(search_result.count).to eq 1
      expect(search_result.first.searchable).to be_a Article
    end

    it "finds podcast episodes", :aggregate_failures do
      search_result = Search::Multisearch.call("searchpodcastepisode")
      expect(search_result.count).to eq 1
      expect(search_result.first.searchable).to be_a PodcastEpisode
    end

    it "searches across different models" do
      search_result = Search::Multisearch.call("search")
      expect(search_result.count).to eq 2
    end

    it "ignores accents when searching" do
      create(:podcast_episode, title: "Piñata", body: "Fun")
      search_result = Search::Multisearch.call("pinata")
      expect(search_result.count).to eq 1
    end
  end
end
