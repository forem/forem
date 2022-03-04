require "rails_helper"

RSpec.describe PodcastEpisode, type: :model do
  let(:podcast_episode) { create(:podcast_episode) }

  describe "validations" do
    describe "builtin validations" do
      subject { podcast_episode }

      it { is_expected.to belong_to(:podcast) }
      it { is_expected.to have_many(:comments).inverse_of(:commentable).dependent(:nullify) }
      it { is_expected.to have_many(:podcast_episode_appearances).dependent(:destroy) }
      it { is_expected.to have_many(:users).through(:podcast_episode_appearances) }

      it { is_expected.to validate_presence_of(:comments_count) }
      it { is_expected.to validate_presence_of(:guid) }
      it { is_expected.to validate_presence_of(:media_url) }
      it { is_expected.to validate_presence_of(:reactions_count) }
      it { is_expected.to validate_presence_of(:slug) }
      it { is_expected.to validate_presence_of(:title) }
    end

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

  describe ".available" do
    let(:podcast) { create(:podcast) }

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
    let(:podcast_episode) { build(:podcast_episode) }

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

    describe "Cloudinary configuration and processing", cloudinary: true do
      it "prefixes an image URL with a path" do
        image_url = "https://dummyimage.com/10x10"
        podcast_episode.body = "<img src=\"#{image_url}\">"
        podcast_episode.validate!
        expect(podcast_episode.processed_html).to include(
          "res.cloudinary.com",
          "c_limit,f_auto,fl_progressive,q_auto,w_725/https://dummyimage.com/10x10",
        )
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
      sidekiq_assert_enqueued_with(job: PodcastEpisodes::BustCacheWorker,
                                   args: [podcast_episode.id, podcast_episode.path, podcast_episode.podcast_slug]) do
        podcast_episode.save
      end
    end
  end
end
