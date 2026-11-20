require "rails_helper"

RSpec.describe "User visits a podcast page" do
  let(:podcast) { create(:podcast) }
  let!(:podcast_episode1) { create(:podcast_episode, podcast_id: podcast.id, published_at: 2.hours.ago) }
  let!(:podcast_episode2) { create(:podcast_episode, podcast_id: podcast.id) }
  let!(:another_episode) { create(:podcast_episode, podcast: create(:podcast)) }

  before { visit podcast.path }

  it "displays the header, published timestamps, and only the podcast's own episodes", :aggregate_failures do
    within "div.spec__podcast-header" do
      expect(page).to have_text(podcast.title)
    end
    expect(page).to have_link(class: "crayons-card", visible: :visible, count: 2)
    expect(page).to have_css("time.published-at")
    expect(page).to have_css("span.time-ago-indicator-initial-placeholder")
    expect(page).to have_link(nil, href: podcast_episode1.path)
    expect(page).to have_link(nil, href: podcast_episode2.path)
    expect(page).to have_no_link(nil, href: another_episode.path)
  end
end
