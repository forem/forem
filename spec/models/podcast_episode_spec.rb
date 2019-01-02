require "rails_helper"

RSpec.describe PodcastEpisode, type: :model do
  let(:podcast_episode) { create(:podcast_episode) }

  it "accepts valid podcast episode" do
    expect(podcast_episode).to be_valid
  end

  describe "#description" do
    it "strips tags from the body" do
      podcast_episode.body = "<h1>Body with HTML tags</h1>"
      expect(podcast_episode.description).to eq("Body with HTML tags")
    end
  end

  describe "#processed_html" do
    it "prefixes an image URL with a Cloudinary path" do
      image_url = "https://dummyimage.com/10x10"
      podcast_episode.body = "<img src=\"#{image_url}\">"
      podcast_episode.validate!
      expect(podcast_episode.processed_html.include?("res.cloudinary.com")).to be(true)
      expect(podcast_episode.processed_html.include?(image_url)).to be(true)
    end
  end
end
