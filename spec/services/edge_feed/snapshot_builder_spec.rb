require "rails_helper"

RSpec.describe EdgeFeed::SnapshotBuilder, type: :service do
  let(:author) { create(:user, :without_profile, profile_image: nil) }
  let(:subforem) { create(:subforem, domain: "edge-poc.example.com") }

  before do
    allow(Settings::UserExperience).to receive_messages(
      feed_lookback_days: 10,
      feed_strategy: "configured",
      feed_config_sticky_hours: 12,
      feed_config_sticky_percentage: 50,
      home_feed_minimum_score: 5,
    )
    allow(Settings::General).to receive(:logo_png).and_return("https://example.com/logo.png")
    allow(PinnedArticle).to receive(:get).and_return(nil)
  end

  describe "#build" do
    it "mirrors qualified articles, active FeedConfigs, and sharded cards", :aggregate_failures do
      qualified = create(
        :article, :past,
        user: author, subforem_id: subforem.id, with_tags: false, with_main_image: false,
        published: true, score: 25, past_published_at: 2.days.ago, cached_tag_list: "rust, fastly"
      )
      create(
        :article, :past,
        user: author, subforem_id: subforem.id, with_tags: false, with_main_image: false,
        published: true, score: 1, past_published_at: 2.days.ago
      )
      create(
        :article, :past,
        user: author, subforem_id: subforem.id, with_tags: false, with_main_image: false,
        published: true, score: 50, past_published_at: 20.days.ago
      )
      active_config = create(:feed_config, archived: false, score_weight: 2.5, targeting_bucket: :feed_casual_user)
      create(:feed_config, archived: true, score_weight: 9.0)

      result = described_class.new(subforem_id: subforem.id, card_shard_count: 4).build

      expect(result.snapshot).to include(
        subforem_id: subforem.id,
        feed_strategy: "configured",
        sticky_hours: 12,
        sticky_percentage: 50,
        card_shard_count: 4,
      )
      expect(result.snapshot[:articles].map { |a| a.fetch(:id) }).to eq([qualified.id])
      expect(result.snapshot[:articles].first[:tags]).to eq(%w[rust fastly])

      serialized_config = result.snapshot[:configs].detect { |c| c[:id] == active_config.id }
      expect(serialized_config[:weights][:score_weight]).to eq(2.5)

      card = result.card_shards[qualified.id % 4][qualified.id.to_s]
      expect(card).to include("id" => qualified.id, "title" => qualified.title, "tag_list" => %w[rust fastly])
      expect(card.keys).not_to include("url", "current_user_signed_in", "feed_config")
    end

    it "includes an older pinned article in both snapshot and card shards so edge assembly never misses it" do
      pinned = create(
        :article, :past,
        user: author, subforem_id: subforem.id, with_tags: false, with_main_image: false,
        published: true, score: 50, past_published_at: 25.days.ago
      )
      allow(PinnedArticle).to receive(:get).and_return(pinned)

      result = described_class.new(subforem_id: subforem.id, card_shard_count: 4).build

      expect(result.snapshot[:pinned_article_id]).to eq(pinned.id)
      expect(result.snapshot[:articles].map { |a| a.fetch(:id) }).to include(pinned.id)
      expect(result.card_shards[pinned.id % 4][pinned.id.to_s]["pinned"]).to be(true)
    end
  end

  describe ".build_host_map" do
    it "maps subforem domains and www aliases to subforem IDs" do
      allow(Subforem).to receive_messages(
        disabled_by_env?: false,
        cached_id_to_domain_hash: { subforem.id => "dev.to" },
      )

      expect(described_class.build_host_map).to eq(
        "dev.to" => subforem.id,
        "www.dev.to" => subforem.id,
      )
    end
  end
end
