module Search
  class Username
    MAX_RESULTS = 6

    ATTRIBUTES = %i[
      id
      name
      profile_image
      username
    ].freeze

    JOIN_COMMENTS = <<-JOIN_SQL.freeze
    LEFT OUTER JOIN comments on (
      comments.user_id = users.id AND
      comments.commentable_type = '%<commentable_type>s' AND
      comments.commentable_id = %<commentable_id>s
    )
    JOIN_SQL

    JOIN_COMMENT_CONTEXT = lambda { |context|
      commentable_type = context.class.polymorphic_name
      commentable_id = context.id
      format(JOIN_COMMENTS, commentable_type: commentable_type, commentable_id: commentable_id)
    }

    # @param term [String] searches on username and name
    # @param context [Article] or [PodcastEpisode]
    #   - used to rank search results by prior comment activity
    #   - connected to comment via polymorphic Commentable
    def self.search_documents(term, context: nil, limit: MAX_RESULTS)
      results = new(context: context).search(term).limit(limit)
      serialize results
    end

    def initialize(context: nil)
      @scope = scope_with_context(context) if context
      @scope ||= scope_without_context
    end

    def search(term)
      scope.search_by_name_and_username(term)
    end

    private

    attr_reader :scope

    def scope_without_context
      ::User.select(*ATTRIBUTES)
    end

    def scope_with_context(context)
      join_sql = JOIN_COMMENT_CONTEXT[context]
      selects = ATTRIBUTES.map { |sym| "users.#{sym}".to_sym }
      # PodcastEpisodes are also commentable but have more complex authorship
      selects << "(users.id = #{context.try(:user_id).to_i}) as is_author"
      selects << "COUNT(comments.id) as comments_count"
      selects << "MAX(comments.created_at) as comment_at"

      ::User.joins(join_sql)
        .group("users.id")
        .select(*selects)
        .order("is_author DESC, comments_count DESC, comment_at ASC")
    end

    def self.serialize(results)
      Search::NestedUserSerializer
        .new(results, is_collection: true)
        .serializable_hash[:data]
        .pluck(:attributes)
    end
    private_class_method :serialize
  end
end
