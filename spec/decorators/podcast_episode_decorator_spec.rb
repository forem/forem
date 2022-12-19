require "rails_helper"

RSpec.describe PodcastEpisodeDecorator, type: :decorator do
  context "with serialization" do
    let(:podcast_episode) { create(:podcast_episode).decorate }

    it "serializes both the decorated object IDs and decorated methods" do
      expected_result = {
        "id" => podcast_episode.id, "published_timestamp" => podcast_episode.published_timestamp
      }
      expect(podcast_episode.as_json(only: [:id], methods: [:published_timestamp])).to eq(expected_result)
    end

    it "serializes collections of decorated objects" do
      podcast_episode # for the side effect

      decorated_collection = PodcastEpisode.decorate
      expected_result = [
        { "id" => podcast_episode.id, "published_timestamp" => podcast_episode.published_timestamp },
      ]
      expect(decorated_collection.as_json(only: [:id], methods: [:published_timestamp])).to eq(expected_result)
    end
  end

  describe "#cached_tag_list_array" do
    it "returns no tags if the tag list is empty" do
      pe = build(:podcast_episode, tag_list: [])
      expect(pe.decorate.cached_tag_list_array).to be_empty
    end

    it "returns tag list" do
      pe = build(:podcast_episode, tag_list: ["discuss"])
      expect(pe.decorate.cached_tag_list_array).to eq(pe.tag_list)
    end
  end

  describe "#readable_publish_date" do
    it "returns empty string if the episode does not have a published_at" do
      pe = build(:podcast_episode, published_at: nil)
      expect(pe.decorate.readable_publish_date).to be_empty
    end

    it "returns the correct date for a same year publication" do
      published_at = Time.current
      pe = build(:podcast_episode, published_at: published_at)
      expect(pe.decorate.readable_publish_date).to eq(published_at.strftime("%b %-e"))
    end

    it "returns the correct date for a publication within a different year" do
      published_at = 2.years.ago
      pe = build(:podcast_episode, published_at: published_at)
      expect(pe.decorate.readable_publish_date).to eq(published_at.strftime("%b %-e '%y"))
    end
  end

  describe "#published_timestamp" do
    it "returns empty string if the episode does not have a published_at" do
      pe = build(:podcast_episode, published_at: nil)
      expect(pe.decorate.published_timestamp).to be_empty
    end

    it "returns the correct date for a published episode" do
      published_at = Time.current
      pe = build(:podcast_episode, published_at: published_at)
      expect(pe.decorate.published_timestamp).to eq(published_at.utc.iso8601)
    end
  end

  describe "#mobile_player_metadata" do
    it "responds with a hash with metadata used in native mobile players" do
      pe = build(:podcast_episode)
      metadata = pe.decorate.mobile_player_metadata
      expect(metadata).to eq({
                               podcastName: pe.podcast.title,
                               episodeName: pe.title,
                               podcastImageUrl: pe.podcast.image_url
                             })
    end
  end
end
