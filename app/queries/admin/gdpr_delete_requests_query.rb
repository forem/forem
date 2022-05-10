module Admin
  class GDPRDeleteRequestsQuery
    QUERY_CLAUSE = "users_gdpr_delete_requests.email ILIKE :search OR " \
                   "users_gdpr_delete_requests.username ILIKE :search".freeze

    def self.call(relation: ::GDPRDeleteRequest.all, options: {})
      role, search = options.values_at(:role, :search)

      relation = relation.with_role(role, :any) if role.presence
      relation = search_relation(relation, search) if search.presence

      relation.order(created_at: :desc)
    end

    def self.search_relation(relation, search)
      relation.where(QUERY_CLAUSE, search: "%#{search.strip}%")
    end
  end
end
