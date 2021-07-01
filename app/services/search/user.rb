module Search
  class User
    ATTRIBUTES = %i[
      id
      name
      profile_image
      username
    ].freeze

    DEFAULT_PER_PAGE = 60
    MAX_PER_PAGE = 100

    # User.search_score used to take employer related fields into account, but they have since been moved to profile
    # and removed from fields that are searched against.
    # rubocop:disable Layout/LineEndStringConcatenationIndentation
    HOTNESS_SCORE_ORDER = Arel.sql(%{
      (((articles_count + comments_count + reactions_count + badge_achievements_count) * 10) * reputation_modifier)
      DESC
    }.squish).freeze
    # rubocop:enable Layout/LineEndStringConcatenationIndentation

    def self.search_documents(term: nil, sort_by: :nil, sort_direction: :desc, page: 0, per_page: DEFAULT_PER_PAGE)
      # NOTE: we should eventually update the frontend
      # to start from page 1
      page = page.to_i + 1
      per_page = [(per_page || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE].min

      relation = ::User

      relation = filter_suspended_users(relation)

      relation = relation.search_by_name_and_username(term) if term.present?

      relation = relation.select(*ATTRIBUTES)

      relation = sort(relation, sort_by, sort_direction)

      relation = relation.page(page).per(per_page)

      serialize(relation)
    end

    # `User.without_role` generates a subquery + 2 inner joins.
    # Given that the number of suspended users will, hopefully, be a tiny percentage
    # of regular users, and the `rolify`'s gem approach is not particularly efficient,
    # we simplified the subquery and added a precondition to skip that query entirely,
    # when a community has no suspended users.
    # NOTE: An alternative approach that could be explored is to
    # preload the user ids of all suspended users and use those with `.where.not(id: ...)`
    def self.filter_suspended_users(relation)
      suspended = UserRole.joins(:role).where(roles: { name: :suspended })

      return relation unless suspended.exists?

      relation.where.not(id: suspended.select(:user_id))
    end
    private_class_method :filter_suspended_users

    def self.sort(relation, sort_by, sort_direction)
      return relation.reorder(sort_by => sort_direction) if sort_by&.to_sym == :created_at

      relation.reorder(HOTNESS_SCORE_ORDER)
    end
    private_class_method :sort

    def self.serialize(users)
      Search::SimpleUserSerializer
        .new(users, is_collection: true)
        .serializable_hash[:data]
        .pluck(:attributes)
    end
    private_class_method :serialize
  end
end
