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

  describe "image cleanup during validation" do
    it "removes empty paragraphs" do
      podcast_episode.body = "<p>\r\n<p>&nbsp;</p>\r\n</p>"
      podcast_episode.validate!
      expect(podcast_episode.processed_html).to eq("<p></p>")
    end

    it "adds a wrapping paragraph" do
      podcast_episode.body = "the body"
      podcast_episode.validate!
      expect(podcast_episode.processed_html).to eq("<p>the body</p>")
    end

    it "does not add a wrapping paragraph if already present" do
      podcast_episode.body = "<p>the body</p>"
      podcast_episode.validate!
      expect(podcast_episode.processed_html).to eq("<p>the body</p>")
    end

    describe "Cloudinary configuration" do
      it "prefixes an image URL with a path" do
        image_url = "https://dummyimage.com/10x10"
        podcast_episode.body = "<img src=\"#{image_url}\">"
        podcast_episode.validate!
        expect(podcast_episode.processed_html.include?("res.cloudinary.com")).to be(true)
      end

      it "chooses the appropriate quality for an image" do
        image_url = "https://dummyimage.com/10x10"
        podcast_episode.body = "<img src=\"#{image_url}\">"
        podcast_episode.validate!
        expect(podcast_episode.processed_html.include?("q_auto")).to be(true)
      end

      it "chooses the appropriate quality for a gif" do
        image_url = "https://dummyimage.com/10x10.gif"
        podcast_episode.body = "<img src=\"#{image_url}\">"
        podcast_episode.validate!
        expect(podcast_episode.processed_html.include?("q_66")).to be(true)
      end
    end
  end
end
