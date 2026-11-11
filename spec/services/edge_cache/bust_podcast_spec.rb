require "rails_helper"

RSpec.describe EdgeCache::BustPodcast, type: :service do
  let(:podcast_path) { "podcast_path" }

  before do
    allow(EdgeCache::PurgeByKey).to receive(:call)
  end

  it "purges podcast and podcast index surrogate keys with fallback paths" do
    described_class.call(podcast_path)

    expect(EdgeCache::PurgeByKey).to have_received(:call).with(
      ["podcasts/#{podcast_path}", "podcast_episodes_all"],
      fallback_paths: ["/#{podcast_path}", "/pod"],
    ).once
  end

  it "includes legacy redirect keys when a podcast claims a former organization slug" do
    former_org = create(:organization)
    former_org.update_columns(old_slug: podcast_path)

    described_class.call(podcast_path)

    expect(EdgeCache::PurgeByKey).to have_received(:call).with(
      ["podcasts/#{podcast_path}", "podcast_episodes_all", former_org.record_key],
      fallback_paths: ["/#{podcast_path}", "/pod"],
    ).once
  end
end
