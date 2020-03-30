module DataUpdateScripts
  class ReIndexFeedContentToElasticsearch
    def run
      clear_existing_feed_documents

      index_docs(Article.pluck(:id), "Article")
      index_docs(PodcastEpisode.pluck(:id), "PodcastEpisode")
      index_docs(Comment.pluck(:id), "Comment")
    end

    private

    def clear_existing_feed_documents
      # Clear out documents with incorrect IDs before reindex
      Search::Client.delete_by_query(
        index: Search::FeedContent::INDEX_ALIAS, body: { query: { match_all: {} } },
      )
    end

    def index_docs(ids, doc_type)
      ids.each do |id|
        Search::IndexToElasticsearchWorker.set(queue: :low_priority).perform_async(
          doc_type, id
        )
      end
    end
  end
end
