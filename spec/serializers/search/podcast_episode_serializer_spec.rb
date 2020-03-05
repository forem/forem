require "rails_helper"

RSpec.describe Search::PodcastEpisodeSerializer do
  let(:user) { create(:user) }
  let(:podcast) { create(:podcast, creator_id: user.id) }
  let(:podcast_ep) { create(:podcast_episode, podcast: podcast) }

  it "serializes a podcast episode" do
    data_hash = described_class.new(podcast_ep).serializable_hash.dig(:data, :attributes)
    user_data = Search::NestedUserSerializer.new(user).serializable_hash.dig(:data, :attributes)
    expect(data_hash[:user]).to eq(user_data)
    expect(data_hash.keys).to include(:id, :body_text)
  end
end
