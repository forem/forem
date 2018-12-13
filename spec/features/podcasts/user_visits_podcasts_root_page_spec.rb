require "rails_helper"

describe "User visits /pod page", type: :feature do
  let!(:podcast_episode) { create(:podcast_episode) }
  let!(:podcast_episode2) { create(:podcast_episode) }

  before { visit "/pod" }

  it "displays the header" do
    within "h1" do
      expect(page).to have_text("Podcasts")
    end
  end

  it "displays the podcasts" do
    within "#articles-list" do
      expect(page).to have_link(nil, href: podcast_episode.path)
      expect(page).to have_link(nil, href: podcast_episode2.path)
    end
  end
end
