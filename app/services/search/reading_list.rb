module Search
  # This class does not inherit from Search::Base like our other search classes bc it
  # is using the FeedContent index to search for ReadingList reaction articles rather than its
  # own separate index. The primary function of this class is to help combine and parse reaction
  # data with article Elasticsearch data to populate the Reading List view.
  class ReadingList
    DEFAULT_PAGE = 0
    DEFAULT_PER_PAGE = 60
    DEFAULT_STATUS = %w[valid confirmed].freeze

    # Using a class method here to follow the pattern of the other Search classes
    def self.search_documents(params:, user:)
      new(params: params, user: user).reading_list_reactions
    end

    def initialize(params:, user:)
      self.status = params.delete(:status) || DEFAULT_STATUS
      self.view_page = params.delete(:page) || DEFAULT_PAGE
      self.view_per_page = params.delete(:per_page) || DEFAULT_PER_PAGE
      self.user = user
      self.search_params = params
    end

    def reading_list_reactions
      ordered_articles = parse_and_order_articles(article_docs)
      { "reactions" => paginate_articles(ordered_articles), "total" => total }
    end

    private

    attr_accessor :search_params, :user, :status, :view_page, :view_per_page, :total

    def paginate_articles(ordered_articles)
      start = view_per_page * view_page
      ordered_articles[start, view_per_page] || []
    end

    def article_docs
      return @article_docs if @article_docs

      # Gather articles from Elasticsearch based on search criteria containing
      # tags, text search, status, and the list of IDs of all articles in a user's
      # reading list
      docs = FeedContent.search_documents(
        params: search_params.merge(
          id: search_ids,
          class_name: "Article",
          page: 0,
          per_page: reading_list_article_ids.count,
        ),
      )
      self.total = docs.count
      @article_docs = docs.index_by { |doc| doc["id"] }
    end

    def reading_list_article_ids
      # Collect all reading list IDs and article IDs for a user
      @reading_list_article_ids ||= user.reactions.readinglist.where(status: status).order(id: :desc).pluck(
        :reactable_id, :id
      ).to_h
    end

    def search_ids
      reading_list_article_ids.keys.map { |id| "article_#{id}" }
    end

    def parse_and_order_articles(articles)
      # Combines reaction and article data to create hashes that contain the fields
      # the reading list view needs. Ensures articles are returned in order of reaction ID
      reading_list_article_ids.filter_map do |article_id, reaction_id|
        found_article_doc = articles[article_id]
        next unless found_article_doc

        { "id" => reaction_id, "user_id" => user.id, "reactable" => articles[article_id] }
      end
    end
  end
end
