module Admin
  class ModeratorsQuery
    DEFAULT_OPTIONS = {
      state: :trusted
    }.with_indifferent_access.freeze

    POTENTIAL_ROLE_NAMES = %i[comment_suspended limited suspended trusted warned].freeze

    def self.call(relation: User.all, options: {})
      options = DEFAULT_OPTIONS.merge(options)
      state, search = options.values_at(:state, :search)

      relation = if state.to_s == "potential"
                   relation.where(
                     "NOT EXISTS (SELECT 1 FROM users_roles " \
                     "WHERE users_roles.user_id = users.id AND users_roles.role_id IN (?))",
                     potential_role_ids,
                   ).order("users.comments_count" => :desc)
                 elsif (role_id = Role.where(name: state).pick(:id))
                   relation.joins(:roles)
                     .where(users_roles: { role_id: role_id })
                 else
                   User.none
                 end

      relation = search_relation(relation, search) if search.presence

      relation
    end

    def self.potential_role_ids
      @potential_role_ids ||= Role.where(name: POTENTIAL_ROLE_NAMES).select(:id)
    end

    def self.search_relation(relation, search)
      relation.where(
        "users.username ILIKE :search OR users.name ILIKE :search",
        search: "%#{search}%",
      )
    end
  end
end
