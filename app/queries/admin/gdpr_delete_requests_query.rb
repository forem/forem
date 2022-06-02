module Admin
  module GDPRDeleteRequestsQuery
    QUERY_CLAUSE = "#{GDPRDeleteRequest.table_name}.email ILIKE :search OR " \
                   "#{GDPRDeleteRequest.table_name}.username ILIKE :search".freeze

    def self.call(relation: ::GDPRDeleteRequest.all, search: {})
      relation = search_relation(relation, search) if search.presence

      relation.order(created_at: :desc)
    end

    def self.search_relation(relation, search)
      relation.where(QUERY_CLAUSE, search: "%#{search}%")
    end
  end
end
