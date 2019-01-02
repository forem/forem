require "rails_helper"

RSpec.describe PodcastEpisode, type: :model do
  let(:podcast_episode) { create(:podcast_episode) }

  it "accept valid podcast episode" do
    expect(podcast_episode).to be_valid
  end

  describe "#description" do
    it "strips tags from the body" do
      podcast_episode.body = "<h1>Body with HTML tags</h1>"
      expect(podcast_episode.description).to eq("Body with HTML tags")
    end
  end
end
