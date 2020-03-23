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
  end

  describe "#after_commit" do
    it "on update enqueues job to index podcast_episode to elasticsearch" do
      podcast_episode.save
      sidekiq_assert_enqueued_with(job: Search::IndexToElasticsearchWorker, args: [described_class.to_s, podcast_episode.search_id]) do
        podcast_episode.save
      end
    end

    it "on destroy enqueues job to delete podcast_episode from elasticsearch" do
      podcast_episode.save
      sidekiq_assert_enqueued_with(job: Search::RemoveFromElasticsearchIndexWorker, args: [described_class::SEARCH_CLASS.to_s, podcast_episode.search_id]) do
        podcast_episode.destroy
      end
    end
  end

  describe "#search_id" do
    it "returns podcast_episode_ID" do
      expect(podcast_episode.search_id).to eq("podcast_episode_#{podcast_episode.id}")
    end
  end

  describe "#description" do
    it "strips tags from the body" do
      ep2 = build(:podcast_episode, guid: podcast_episode.guid)

      ep2.body = "<h1>Body with HTML tags</h1>"
      expect(ep2.description).to eq("Body with HTML tags")
    end
  end

  describe "#index_id" do
    it "is equal to articles-ID" do
      # NOTE: we shouldn't test private things but cheating a bit for Algolia here
      expect(podcast_episode.send(:index_id)).to eq("podcast_episodes-#{podcast_episode.id}")
    end
  end

  describe "#mobile_player_metadata" do
    it "responds with a hash with metadata used in native mobile players" do
      metadata = podcast_episode.mobile_player_metadata
      expect(metadata).to be_instance_of(Hash)
      expect(metadata[:podcastName]).to eq(podcast_episode.podcast.title)
      expect(metadata[:episodeName]).to eq(podcast_episode.title)
      expect(metadata[:podcastImageUrl]).to include(podcast_episode.podcast.image_url)
    end
  end

  describe ".available" do
    let_it_be(:podcast) { create(:podcast) }

    it "is available when reachable and published" do
      expect do
        create(:podcast_episode, podcast: podcast)
      end.to change(described_class.available, :count).by(1)
    end

    it "is not available when unreachable" do
      expect do
        create(:podcast_episode, podcast: podcast, reachable: false)
      end.to change(described_class.available, :count).by(0)
    end

    it "is not available when podcast is unpublished" do
      expect do
        podcast = create(:podcast, published: false)
        create(:podcast_episode, podcast: podcast)
      end.to change(described_class.available, :count).by(0)
    end
  end

  context "when callbacks are triggered before validation" do
    let_it_be(:podcast_episode) { build(:podcast_episode) }

    describe "paragraphs cleanup" do
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
    end

    describe "Cloudinary configuration and processing" do
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

  context "when callbacks are triggered after save" do
    it "triggers cache busting on save" do
      sidekiq_assert_enqueued_with(job: PodcastEpisodes::BustCacheWorker, args: [podcast_episode.id, podcast_episode.path, podcast_episode.podcast_slug]) do
        podcast_episode.save
      end
    end
  end
end
