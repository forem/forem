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
      new(
        context: context, 
        priority_user_ids: priority_user_ids,
        recent_user_ids: recent_user_ids,
        requesting_user_id: requesting_user_id
      ).search(term, limit)
    end

    def self.serialize(results)
      Search::NestedUserSerializer
        .new(results, is_collection: true)
        .serializable_hash[:data]
        .pluck(:attributes)
    end

    def initialize(context: nil, priority_user_ids: [], recent_user_ids: nil, requesting_user_id: nil)
      frontend_provided_priorities = priority_user_ids.present?

      @priority_user_ids = Array(priority_user_ids).compact_blank.map(&:to_i)
      @requesting_user_id = requesting_user_id
      
      if context
        @priority_user_ids << context.try(:user_id)
        @priority_user_ids += context.co_author_ids if context&.co_author_ids.present?

        unless frontend_provided_priorities
          @priority_user_ids += ::Comment.where(commentable: context).pluck(:user_id)
        end
      end
      
      @priority_user_ids = @priority_user_ids.compact.uniq
      @recent_user_ids = Array(recent_user_ids).compact_blank.map(&:to_i)
    end

    def search(term, limit)
      users = []

      if @priority_user_ids.any?
        priority_scope = scope_without_context.where(id: @priority_user_ids)
        priority_scope = priority_scope.where.not(id: @requesting_user_id) if @requesting_user_id.present?
        users += priority_scope.search_by_name_and_username(term).where("users.score >= 0").limit(limit).to_a
      end

      if users.size < limit && @recent_user_ids.any?
        recent_scope = scope_without_context.where(id: @recent_user_ids)
        recent_scope = recent_scope.where.not(id: users.map(&:id)) if users.any?
        recent_scope = recent_scope.where.not(id: @requesting_user_id) if @requesting_user_id.present?
        users += recent_scope.search_by_name_and_username(term).where("users.score >= 0").limit(limit - users.size).to_a
      end

      if users.size < limit
        global_scope = scope_without_context.where("users.score >= 0")
        global_scope = global_scope.where.not(id: users.map(&:id)) if users.any?
        global_scope = global_scope.where.not(id: @requesting_user_id) if @requesting_user_id.present?
        users += global_scope.search_by_name_and_username(term).order(score: :desc).limit(limit - users.size).to_a
      end

      self.class.send(:serialize, users)
    end

    private

    def scope_without_context
      ::User.select(*ATTRIBUTES)
    end

    private_class_method :serialize
  end
end
