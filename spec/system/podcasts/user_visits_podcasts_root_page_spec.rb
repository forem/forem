require "rails_helper"

RSpec.describe "User visits /pod page", type: :system do
  let!(:podcast_episode1) { create(:podcast_episode, published_at: 7.hours.ago) }
  let!(:podcast_episode2) { create(:podcast_episode, published_at: 7.days.ago) }
  let!(:podcast_episode3) { create(:podcast_episode) }
  let(:podcast) { create(:podcast, reachable: true, published: false) }
  let(:unpublished_podcast) { create(:podcast, reachable: false) }
  let!(:un_podcast_episode) { create(:podcast_episode, podcast: podcast, reachable: false) }
  let!(:unpublished_episode) { create(:podcast_episode, podcast: podcast) }

  before { visit "/pod" }

  it "displays the podcasts", js: true do
    within "#main-content" do
      expect(page).to have_link(nil, href: podcast_episode1.path)
      expect(page).to have_link(nil, href: podcast_episode2.path)
      expect(page).to have_link(nil, href: podcast_episode3.path)
    end
  end

  it "displays the podcasts with published_at" do
    within "#main-content" do
      expect(page).to have_selector("time.published-at", count: 2)
      expect(page).to have_selector("span.time-ago-indicator-initial-placeholder", count: 2)
    end
  end

  it "doesn't display an unreachable podcast" do
    within "#main-content" do
      expect(page).not_to have_link(nil, href: un_podcast_episode.path)
    end
  end

  it "doesn't dsplay a podcast that is not published" do
    within "#main-content" do
      expect(page).not_to have_link(nil, href: unpublished_episode.path)
    end
  end
end
