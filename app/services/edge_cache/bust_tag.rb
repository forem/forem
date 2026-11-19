module EdgeCache
  class BustTag
    def self.call(tag)
      return unless tag

      EdgeCache::PurgeByKey.call(
        [tag.record_key, Tag.table_key, Tag::SUPPORTED_TAGS_SURROGATE_KEY],
        fallback_paths: ["/t/#{tag.name}", "/t/#{tag.name}/", "/tags"],
      )
    end
  end
end
