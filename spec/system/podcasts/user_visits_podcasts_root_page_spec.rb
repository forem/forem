require "rails_helper"

RSpec.describe "User visits /pod page", type: :system do
  let!(:podcast_episode) { create(:podcast_episode) }
  let!(:podcast_episode2) { create(:podcast_episode) }
  let(:podcast) { create(:podcast, reachable: false) }
  let!(:un_podcast_episode) { create(:podcast_episode, podcast: podcast, reachable: false) }

  before { visit "/pod" }

  it "displays the podcasts" do
    within "#articles-list" do
      expect(page).to have_link(nil, href: podcast_episode.path)
      expect(page).to have_link(nil, href: podcast_episode2.path)
    end
  end

  it "doesn't display an unreachable podcast" do
    within "#articles-list" do
      expect(page).not_to have_link(nil, href: un_podcast_episode.path)
    end
  end
end
