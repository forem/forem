require "rails_helper"

RSpec.describe EdgeFeed::SyncSnapshotsWorker, type: :worker do
  let(:kv_client) { instance_double(EdgeFeed::KvClient, put: :written) }
  let(:build_result) do
    EdgeFeed::SnapshotBuilder::Result.new(
      snapshot: { version: 1, subforem_id: 1 },
      card_shards: [{ "10" => { "id" => 10 } }, {}],
      embeddings: { entries: [] },
    )
  end

  before do
    allow(EdgeFeed::KvClient).to receive_messages(configured?: true, new: kv_client)
    allow(EdgeFeed::SnapshotBuilder).to receive(:build_host_map).and_return("dev.to" => 1)
    allow(Subforem).to receive_messages(disabled_by_env?: false, cached_id_to_domain_hash: { 1 => "dev.to" })
    builder = instance_double(EdgeFeed::SnapshotBuilder, build: build_result)
    allow(EdgeFeed::SnapshotBuilder).to receive(:new).with(subforem_id: 1).and_return(builder)
  end

  it "does nothing when the :fastly_edge_feed_mirror feature flag is disabled" do
    FeatureFlag.disable(:fastly_edge_feed_mirror)

    described_class.new.perform

    expect(kv_client).not_to have_received(:put)
  end

  it "mirrors host_map, snapshot, embeddings, and card shards when enabled" do
    FeatureFlag.enable(:fastly_edge_feed_mirror)

    described_class.new.perform

    expect(kv_client).to have_received(:put).with("host_map", { "dev.to" => 1 })
    expect(kv_client).to have_received(:put).with("snapshot:1", { version: 1, subforem_id: 1 })
    expect(kv_client).to have_received(:put).with("embeddings:1", { entries: [] })
    expect(kv_client).to have_received(:put).with("cards:1:0", { "10" => { "id" => 10 } })
    expect(kv_client).to have_received(:put).with("cards:1:1", {})
  ensure
    FeatureFlag.disable(:fastly_edge_feed_mirror)
  end
end
