module DataSync
  module Elasticsearch
    class Tag < Base
      RELATED_DOCS = %i[
        articles
        podcast_episodes
      ].freeze

      SHARED_FIELDS = %i[
        keywords_for_search
      ].freeze

      private

      def articles
        ::Article.cached_tagged_with(updated_record.name)
      end

      def reactions
        ::Reaction.readinglist.where(reactable: articles)
      end

      def podcast_episodes
        ::PodcastEpisode.where(
          id: updated_record.taggings.where(taggable_type: "PodcastEpisode").select(:taggable_id),
        )
      end
    end
  end
end
