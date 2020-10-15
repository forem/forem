module Admin
  class ModeratorsQuery
    DEFAULT_OPTIONS = {
      state: :trusted
    }.with_indifferent_access.freeze

    def self.call(relation: User.all, options: {})
      options = DEFAULT_OPTIONS.merge(options)
      state, search = options.values_at(:state, :search)

      relation = if state.to_s == "potential"
                   relation.where(
                     "id NOT IN (SELECT user_id FROM users_roles WHERE role_id = ?)
                     AND id NOT IN (SELECT user_id FROM users_roles WHERE role_id = ?)",
                     role_id_for(:trusted),
                     role_id_for(:banned),
                   ).order("users.comments_count" => :desc)
                 else
                   relation.joins(:roles)
                     .where(users_roles: { role_id: role_id_for(state) })
                 end

      relation = search_relation(relation, search) if search.presence

      relation
    end

    def self.role_id_for(role)
      Role.find_by(name: role)&.id
    end

    def self.search_relation(relation, search)
      relation.where(
        "users.username ILIKE :search OR users.name ILIKE :search",
        search: "%#{search}%",
      )
    end
  end
end
