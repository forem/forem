require "rails_helper"

RSpec.describe "podcast_episodes/index" do
  let(:podcast) { create(:podcast) }
  let(:podcast_episodes) { create_list(:podcast_episode, 5, podcast: podcast) }

  before do
    assign(:podcast_episodes, podcast_episodes)
    assign(:more_podcasts, Podcast.available.order(title: :asc))
  end

  it "shows the Browse section with the title of the only podcast" do
    render

    expect(rendered).to have_content("Browse")
    expect(rendered).to have_content(podcast.title)
  end

  context "when there are featured podcasts" do
    let(:featured_podcast) { create(:podcast, featured: true) }

    before do
      create_list(:podcast_episode, 2, podcast: featured_podcast)
      assign(:featured_podcasts, Podcast.available.featured.order(title: :asc).limit(4))
    end

    it "shows the Featured podcasts section" do
      render

      expect(rendered).to have_content("Featured")
      expect(rendered).to have_content(featured_podcast.title)
    end
  end
end
