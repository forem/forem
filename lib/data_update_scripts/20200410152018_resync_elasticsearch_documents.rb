module DataUpdateScripts
  class ResyncElasticsearchDocuments
    def run
      # Previous bug: Not getting removed properly
      # sync_docs(Article.ids, "Article")
      # sync_docs(Comment.ids, "Comment")
      # sync_docs(User.ids, "User")

      # Previous bug: Not getting indexed on creation properly
      # index_docs(PodcastEpisode.ids, "PodcastEpisode")
      # index_docs(Tag.ids, "Tag")
    end

    private

    def index_docs(ids, doc_type)
      ids.each do |id|
        Search::IndexWorker.set(queue: :low_priority).perform_async(
          doc_type, id
        )
      end
    end

    # This is essentially doing a "find_each" in Elasticsearch by scrolling through
    # all of the documents and collecting their IDs. Then we remove the mismatched Postgres ones
    def sync_docs(db_ids, doc_type)
      es_ids = []
      response = Search::Client.search(
        index: search_class(doc_type)::INDEX_ALIAS, scroll: "2m", body: search_body(doc_type), size: 3000,
      )
      loop do
        hits = response.dig("hits", "hits")
        break if hits.empty?

        hits.each do |hit|
          es_ids << hit["_id"].split("_").last.to_i
        end

        response = Search::Client.scroll(body: { scroll_id: response["_scroll_id"] }, scroll: "2m")
      end

      remove_ids(db_ids, es_ids, doc_type)
    end

    def ids_to_remove(db_ids, es_ids, doc_type)
      dif = es_ids - db_ids
      doc_type == "User" ? dif : dif.map { |id| "#{doc_type.downcase}_#{id}" }
    end

    def remove_ids(db_ids, es_ids, doc_type)
      dif_ids = ids_to_remove(db_ids, es_ids, doc_type)
      index_name = search_class(doc_type)::INDEX_ALIAS
      dif_ids.map do |id|
        Search::Client.delete(id: id, index: index_name)
      end
    end

    def search_body(doc_type)
      if doc_type == "User"
        { query: { match_all: {} }, _source: [:id] }
      else
        {
          query: {
            bool: { filter: { term: { class_name: doc_type } } }
          },
          _source: [:id]
        }
      end
    end

    def search_class(doc_type)
      doc_type == "User" ? Search::User : Search::FeedContent
    end
  end
end
