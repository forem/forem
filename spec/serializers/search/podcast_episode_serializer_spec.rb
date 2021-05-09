require "rails_helper"

RSpec.describe Search::PodcastEpisodeSerializer do
  let(:pce) { create(:podcast_episode) }

  it "serializes a PodcastEpisode" do
    data_hash = described_class.new(pce).serializable_hash.dig(:data, :attributes)
    expect(data_hash.keys).to include(
      :id, :body_text, :comments_count, :path, :published_at, :quote, :reactions_count, :subtitle,
      :summary, :title, :website_url, :class_name, :highlight, :hotness_score, :main_image,
      :podcast, :public_reactions_count, :published, :search_score, :slug, :user
    )
  end

  it "serializes podcast" do
    podcast = described_class.new(pce).serializable_hash.dig(:data, :attributes, :podcast)
    expect(podcast.keys).to include(:slug, :image_url, :title)
    expect(podcast[:slug]).to eq(pce.podcast_slug)
    expect(podcast[:image_url]).to eq(Images::Profile.call(pce.podcast.profile_image_url, length: 90))
    expect(podcast[:title]).to eq(pce.title)
  end
end
