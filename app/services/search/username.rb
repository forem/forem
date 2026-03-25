module Search
  class Username
    MAX_RESULTS = 6

    ATTRIBUTES = %i[
      id
      name
      profile_image
      username
    ].freeze

    # @param term [String] searches on username and name
    # @param context [Article] or [PodcastEpisode]
    #   - used to rank search results by prior comment activity
    #   - connected to comment via polymorphic Commentable
    def self.search_documents(term, context: nil, priority_user_ids: [], recent_user_ids: nil, requesting_user_id: nil, limit: MAX_RESULTS)
      results = new(
        context: context, 
        priority_user_ids: priority_user_ids,
        recent_user_ids: recent_user_ids,
        requesting_user_id: requesting_user_id
      ).search(term).limit(limit)
      serialize results
    end

    def self.serialize(results)
      Search::NestedUserSerializer
        .new(results, is_collection: true)
        .serializable_hash[:data]
        .pluck(:attributes)
    end

    def initialize(context: nil, priority_user_ids: [], recent_user_ids: nil, requesting_user_id: nil)
      @priority_user_ids = Array(priority_user_ids).compact_blank.map(&:to_i)
      @requesting_user_id = requesting_user_id
      
      if context
        @priority_user_ids << context.try(:user_id)
        @priority_user_ids += context.co_author_ids if context&.co_author_ids.present?

        if @priority_user_ids.empty?
          @priority_user_ids += ::Comment.where(commentable: context).pluck(:user_id)
        end
      end
      
      @priority_user_ids = @priority_user_ids.compact.uniq
      @recent_user_ids = Array(recent_user_ids).compact_blank.map(&:to_i)
      
      @scope = scope_with_priorities
    end

    def search(term)
      @scope.search_by_name_and_username(term)
    end

    private

    def scope_without_context
      ::User.select(*ATTRIBUTES)
    end

    def scope_with_priorities
      selects = ATTRIBUTES.map { |sym| "users.#{sym}".to_sym }
      order_clauses = []

      if @priority_user_ids.any?
        selects << ::User.sanitize_sql(["users.id IN (?) as is_priority", @priority_user_ids])
        order_clauses << "is_priority DESC"
      end

      if @recent_user_ids.any?
        selects << ::User.sanitize_sql(["users.id IN (?) as is_recent", @recent_user_ids])
        order_clauses << "is_recent DESC"
      end

      order_clauses << "users.score DESC"

      scope = ::User
        .select(*selects)
        .order(::Arel.sql(order_clauses.join(", ")))

      scope = scope.where.not(id: @requesting_user_id) if @requesting_user_id.present?
      scope
    end

    private_class_method :serialize
  end
end
