require "rails_helper"

RSpec.describe "User visits a podcast page", type: :system do
  let(:podcast) { create(:podcast) }
  let!(:podcast_episode) { create(:podcast_episode, podcast_id: podcast.id) }
  let!(:podcast_episode2) { create(:podcast_episode, podcast_id: podcast.id) }
  let(:another_episode) { create(:podcast_episode, podcast: create(:podcast)) }
  let(:user) { create(:user) }

  before { visit podcast.path }

  it "displays the header" do
    within "div.podcast-header" do
      expect(page).to have_text(podcast.title)
    end
  end

  it "displays podcast episodes" do
    expect(page).to have_selector("div.single-article", visible: true, count: 2)
  end

  it "displays correct episodes" do
    expect(page).to have_link(nil, href: podcast_episode.path)
    expect(page).to have_link(nil, href: podcast_episode2.path)
    expect(page).not_to have_link(nil, href: another_episode.path)
  end
end
