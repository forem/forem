module EdgeFeed
  # Periodically mirrors each active subforem's qualified home-feed articles, active
  # FeedConfigs, sharded pre-rendered story cards, quantized embeddings, and host map
  # to Fastly KV Store.
  #
  # Completely inert unless `:fastly_edge_feed_mirror` is enabled and Fastly KV Store
  # credentials (`FASTLY_API_KEY` + `FASTLY_FEED_KV_STORE_ID`) are configured.
  class SyncSnapshotsWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 3, lock: :until_executing, on_conflict: :replace

    def perform(subforem_id = nil)
      return unless FeatureFlag.enabled?(:fastly_edge_feed_mirror)
      return unless EdgeFeed::KvClient.configured?

      client = EdgeFeed::KvClient.new
      sync_host_map(client) if subforem_id.nil?

      target_subforem_ids(subforem_id).each do |sf_id|
        sync_subforem(client, sf_id)
      end
    end

    private

    def sync_host_map(client)
      host_map = EdgeFeed::SnapshotBuilder.build_host_map
      client.put("host_map", host_map) if host_map.any?
    end

    def sync_subforem(client, subforem_id)
      result = EdgeFeed::SnapshotBuilder.new(subforem_id: subforem_id).build

      client.put("snapshot:#{subforem_id}", result.snapshot)
      client.put("embeddings:#{subforem_id}", result.embeddings)
      result.card_shards.each_with_index do |cards, shard_idx|
        client.put("cards:#{subforem_id}:#{shard_idx}", cards)
      end
    end

    def target_subforem_ids(explicit_id)
      return [explicit_id.to_i] if explicit_id.present?
      return [Subforem.cached_default_id].compact if Subforem.disabled_by_env?

      Subforem.cached_id_to_domain_hash.keys
    end
  end
end
