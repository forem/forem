require "rails_helper"

RSpec.describe PodcastEpisode, type: :model do
  let(:podcast_episode) { create(:podcast_episode) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:slug) }
  it { is_expected.to validate_presence_of(:media_url) }
  it { is_expected.to validate_presence_of(:guid) }

  describe "validations" do
    # Couldn't use shoulda matchers for these tests because:
    # Shoulda uses `save(validate: false)` which skips validations, but runs callbacks
    # So an invalid record is saved and the algolia callback fails to run because there's no associated podcast
    # https://git.io/fjg2g

    it "validates guid uniqueness" do
      ep2 = build(:podcast_episode, guid: podcast_episode.guid)

      expect(ep2).not_to be_valid
      expect(ep2.errors[:guid]).to be_present
    end

    it "validates media_url uniqueness" do
      ep2 = build(:podcast_episode, media_url: podcast_episode.media_url)

      expect(ep2).not_to be_valid
      expect(ep2.errors[:media_url]).to be_present
    end

    it "accepts valid podcast episode" do
      expect(podcast_episode).to be_valid
    end
  end

  describe "#available" do
    let(:podcast) { create(:podcast) }
    let(:unpodcast) { create(:podcast, published: false) }
    let!(:episode) { create(:podcast_episode, podcast: podcast) }

    before do
      create(:podcast_episode, podcast: unpodcast)
      create(:podcast_episode, podcast: podcast, reachable: false)
    end

    it "is available when reachable and published" do
      available_ids = described_class.available.pluck(:id)
      expect(available_ids).to eq([episode.id])
    end
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

  it "triggers cache busting on save" do
    expect { build(:podcast_episode).save }.to have_enqueued_job.on_queue("podcast_episodes_bust_cache")
  end
end
