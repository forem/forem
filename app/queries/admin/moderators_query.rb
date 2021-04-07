module Admin
  class ModeratorsQuery
    DEFAULT_OPTIONS = {
      state: :trusted
    }.with_indifferent_access.freeze

    # TODO: [@jacobherrington] Once all Forems have been deployed and the data update scripts have
    # succesfully completed, we can remove banned and comment_banned roles from the codebase
    VALID_ROLES = %i[banned comment_banned comment_suspended suspended trusted warned].freeze

    def self.call(relation: User.all, options: {})
      options = DEFAULT_OPTIONS.merge(options)
      state, search = options.values_at(:state, :search)
      role_id = Role.find_by(name: state)&.id

      relation = if state.to_s == "potential"
                   relation.where(
                     "id NOT IN (SELECT user_id FROM users_roles WHERE role_id IN (?))",
                     potential_role_ids,
                   ).order("users.comments_count" => :desc)
                 elsif role_id.present?
                   relation.joins(:roles)
                     .where(users_roles: { role_id: role_id })
                 else
                   User.none
                 end

      relation = search_relation(relation, search) if search.presence

      relation
    end

    def self.potential_role_ids
      @potential_role_ids ||= Role.where(name: VALID_ROLES).select(:id)
    end

    def self.search_relation(relation, search)
      relation.where(
        "users.username ILIKE :search OR users.name ILIKE :search",
        search: "%#{search}%",
      )
    end
  end
end
